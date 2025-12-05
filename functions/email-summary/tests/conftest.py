import os
import pytest
from unittest.mock import Mock, patch, MagicMock
from moto import mock_aws
import boto3
from fastapi.testclient import TestClient
import json

# Set environment variables before importing main
os.environ["SES_SENDER_EMAIL_ADDRESS"] = "sender@example.com"
os.environ["TEMPLATE_NAME"] = "retroboard-summary"

from main import app


@pytest.fixture
def mock_ses_client():
    """Mock SES client"""
    with mock_aws():
        client = boto3.client("ses", region_name="us-east-1")
        # Verify sender email
        client.verify_email_identity(EmailAddress="sender@example.com")
        # Create email template
        try:
            client.create_template(
                Template={
                    "TemplateName": "retroboard-summary",
                    "SubjectPart": "Retroboard Summary",
                    "HtmlPart": "<h1>Retroboard Summary</h1><p>{{notes_text}}</p>",
                    "TextPart": "{{notes_text}}",
                }
            )
        except client.exceptions.AlreadyExistsException:
            pass  # Template already exists
        yield client


@pytest.fixture
def test_client(mock_ses_client):
    """Create a test client with mocked SES"""
    with patch("main.ses_client", mock_ses_client):
        client = TestClient(app)
        yield client


@pytest.fixture
def sample_sqs_message():
    """Sample SQS message in Lambda event format"""
    email_payload = {
        "to": "recipient@example.com",
        "board_slug": "test-board",
        "total_notes": 5,
        "total_votes": 10,
        "notes_text": "## Section 1\n- 2 x 👍 | Note 1\n",
    }
    return {
        "Records": [
            {
                "body": json.dumps(email_payload),
                "messageId": "test-message-id",
                "receiptHandle": "test-receipt-handle",
            }
        ]
    }


@pytest.fixture
def multiple_sqs_messages():
    """Multiple SQS messages"""
    return {
        "Records": [
            {
                "body": json.dumps(
                    {
                        "to": "recipient1@example.com",
                        "board_slug": "board-1",
                        "total_notes": 3,
                        "total_votes": 5,
                        "notes_text": "## Section 1\n- Note 1\n",
                    }
                ),
                "messageId": "msg-1",
            },
            {
                "body": json.dumps(
                    {
                        "to": "recipient2@example.com",
                        "board_slug": "board-2",
                        "total_notes": 2,
                        "total_votes": 3,
                        "notes_text": "## Section 2\n- Note 2\n",
                    }
                ),
                "messageId": "msg-2",
            },
        ]
    }
