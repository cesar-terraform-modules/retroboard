import os
import pytest
from unittest.mock import Mock, patch, MagicMock
from fastapi.testclient import TestClient
import json

# Set environment variables before importing main
os.environ["SLACK_WEBHOOK_URL"] = "https://hooks.slack.com/services/TEST/WEBHOOK/URL"

from main import app


@pytest.fixture
def mock_http_response():
    """Mock urllib3 HTTP response"""
    mock_response = MagicMock()
    mock_response.status = 200
    mock_response.data = b'{"ok": true}'
    return mock_response


@pytest.fixture
def mock_pool_manager(mock_http_response):
    """Mock urllib3 PoolManager"""
    mock_manager = MagicMock()
    mock_manager.request.return_value = mock_http_response
    return mock_manager


@pytest.fixture
def test_client(mock_pool_manager):
    """Create a test client with mocked HTTP"""
    with patch("main.http", mock_pool_manager):
        client = TestClient(app)
        yield client
        # Reset mock after test
        mock_pool_manager.reset_mock()


@pytest.fixture
def sns_lambda_event_format():
    """SNS message in Lambda event format"""
    return {
        "Records": [
            {
                "Sns": {
                    "Message": "New board created: Test Board with slug: test-board and id abc123",
                    "MessageId": "test-message-id",
                    "TopicArn": "arn:aws:sns:us-east-1:123456789012:retroboard-alerts",
                }
            }
        ]
    }


@pytest.fixture
def sns_direct_http_format():
    """SNS message in direct HTTP notification format"""
    return {
        "Type": "Notification",
        "MessageId": "test-message-id",
        "TopicArn": "arn:aws:sns:us-east-1:123456789012:retroboard-alerts",
        "Message": "New board created: Test Board with slug: test-board and id abc123",
        "Timestamp": "2024-01-01T00:00:00.000Z",
        "SignatureVersion": "1",
        "Signature": "test-signature",
        "SigningCertURL": "https://sns.us-east-1.amazonaws.com/cert.pem",
        "UnsubscribeURL": "https://sns.us-east-1.amazonaws.com/unsubscribe",
    }
