import pytest
from unittest.mock import patch, MagicMock, call
from fastapi import status
import json


def test_process_notification_lambda_format_root(
    test_client, sns_lambda_event_format, mock_pool_manager
):
    """Test processing notification via root endpoint with Lambda event format"""
    response = test_client.post("/", json=sns_lambda_event_format)

    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["status"] == "success"
    assert data["slack_status"] == 200

    # Verify Slack webhook was called
    assert mock_pool_manager.request.called
    call_args = mock_pool_manager.request.call_args
    assert call_args[0][0] == "POST"
    assert call_args[0][1] == "https://hooks.slack.com/services/TEST/WEBHOOK/URL"

    # Verify payload
    payload = json.loads(call_args[1]["body"])
    assert payload["text"] == sns_lambda_event_format["Records"][0]["Sns"]["Message"]


def test_process_notification_lambda_format_process(
    test_client, sns_lambda_event_format, mock_pool_manager
):
    """Test processing notification via /process endpoint with Lambda event format"""
    response = test_client.post("/process", json=sns_lambda_event_format)

    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["status"] == "success"
    assert data["slack_status"] == 200


def test_process_notification_direct_http_format(
    test_client, sns_direct_http_format, mock_pool_manager
):
    """Test processing notification with direct SNS HTTP notification format"""
    response = test_client.post("/", json=sns_direct_http_format)

    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["status"] == "success"
    assert data["slack_status"] == 200

    # Verify Slack webhook was called with correct message
    call_args = mock_pool_manager.request.call_args
    payload = json.loads(call_args[1]["body"])
    assert payload["text"] == sns_direct_http_format["Message"]


def test_process_notification_webhook_failure(test_client, sns_lambda_event_format):
    """Test handling notification webhook failure"""
    # Create a mock that returns error status
    mock_response = MagicMock()
    mock_response.status = 500
    mock_response.data = b'{"error": "Internal Server Error"}'

    mock_manager = MagicMock()
    mock_manager.request.return_value = mock_response

    with patch("main.http", mock_manager):
        client = test_client
        response = client.post("/", json=sns_lambda_event_format)

        assert response.status_code == status.HTTP_502_BAD_GATEWAY
        data = response.json()
        assert "detail" in data
        assert "Notification webhook returned error" in data["detail"]


def test_process_notification_invalid_format(test_client):
    """Test handling invalid message format"""
    invalid_message = {"invalid": "format"}

    response = test_client.post("/", json=invalid_message)

    assert response.status_code == status.HTTP_400_BAD_REQUEST
    data = response.json()
    assert "detail" in data
    assert "Invalid message format" in data["detail"]


def test_process_notification_empty_records(test_client):
    """Test handling empty Records array"""
    empty_message = {"Records": []}

    response = test_client.post("/", json=empty_message)

    assert response.status_code == status.HTTP_400_BAD_REQUEST
    data = response.json()
    assert "Invalid message format" in data["detail"]


def test_process_notification_missing_message_field(test_client):
    """Test handling message with missing Message field in direct format"""
    invalid_message = {
        "Type": "Notification",
        "MessageId": "test-id",
        # Missing "Message" field
    }

    response = test_client.post("/", json=invalid_message)

    assert response.status_code == status.HTTP_400_BAD_REQUEST


def test_process_notification_verifies_webhook_payload(
    test_client, sns_lambda_event_format, mock_pool_manager
):
    """Test that Slack webhook receives correct JSON payload format"""
    test_message = "Test alert message"
    sns_lambda_event_format["Records"][0]["Sns"]["Message"] = test_message

    response = test_client.post("/", json=sns_lambda_event_format)

    assert response.status_code == status.HTTP_200_OK

    # Verify the payload structure
    call_args = mock_pool_manager.request.call_args
    payload = json.loads(call_args[1]["body"])
    assert payload == {"text": test_message}
    assert isinstance(call_args[1]["body"], bytes)


def test_process_notification_handles_webhook_timeout(
    test_client, sns_lambda_event_format
):
    """Test handling webhook timeout/connection error"""
    mock_manager = MagicMock()
    mock_manager.request.side_effect = Exception("Connection timeout")

    with patch("main.http", mock_manager):
        client = test_client
        response = client.post("/", json=sns_lambda_event_format)

        assert response.status_code == status.HTTP_500_INTERNAL_SERVER_ERROR
        data = response.json()
        assert "detail" in data
        assert "Error processing notification" in data["detail"]
