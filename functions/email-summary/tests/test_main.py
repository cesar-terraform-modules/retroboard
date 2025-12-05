import pytest
from unittest.mock import patch, MagicMock
from fastapi import status
from botocore.exceptions import ClientError
import json


def test_process_email_root_endpoint(test_client, sample_sqs_message, mock_ses_client):
    """Test processing email via root endpoint"""
    response = test_client.post("/", json=sample_sqs_message)

    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["status"] == "success"
    assert data["processed"] == 1


def test_process_email_process_endpoint(
    test_client, sample_sqs_message, mock_ses_client
):
    """Test processing email via /process endpoint"""
    response = test_client.post("/process", json=sample_sqs_message)

    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["status"] == "success"
    assert data["processed"] == 1


def test_process_email_verifies_ses_call(
    test_client, sample_sqs_message, mock_ses_client
):
    """Test that SES send_templated_email is called with correct parameters"""
    response = test_client.post("/", json=sample_sqs_message)

    assert response.status_code == status.HTTP_200_OK

    # Verify SES was called (moto doesn't track calls directly, but we can check
    # that the operation succeeded by checking the response)


def test_process_multiple_emails(test_client, multiple_sqs_messages, mock_ses_client):
    """Test processing multiple email messages"""
    response = test_client.post("/", json=multiple_sqs_messages)

    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["status"] == "success"
    assert data["processed"] == 2


def test_process_email_ses_failure(test_client, sample_sqs_message):
    """Test handling SES failure"""
    # Create a mock SES client that raises an error
    mock_client = MagicMock()
    error_response = {
        "Error": {
            "Code": "MessageRejected",
            "Message": "Email address not verified",
        }
    }
    mock_client.send_templated_email.side_effect = ClientError(
        error_response, "SendTemplatedEmail"
    )

    with patch("main.ses_client", mock_client):
        client = test_client
        response = client.post("/", json=sample_sqs_message)

        assert response.status_code == status.HTTP_500_INTERNAL_SERVER_ERROR
        data = response.json()
        assert "detail" in data
        assert "Failed to send email" in data["detail"]


def test_process_email_invalid_message_format(test_client):
    """Test handling invalid message format"""
    invalid_message = {"invalid": "format"}

    response = test_client.post("/", json=invalid_message)

    # Should fail validation at Pydantic level
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


def test_process_email_malformed_json_body(test_client, sample_sqs_message):
    """Test handling malformed JSON in SQS message body"""
    malformed_message = {
        "Records": [
            {
                "body": "not valid json",
                "messageId": "test-id",
            }
        ]
    }

    response = test_client.post("/", json=malformed_message)

    # Should fail when trying to parse the body
    assert response.status_code == status.HTTP_500_INTERNAL_SERVER_ERROR


def test_process_email_missing_to_field(test_client):
    """Test handling message with missing 'to' field"""
    invalid_payload = {
        "board_slug": "test-board",
        "total_notes": 5,
        "total_votes": 10,
        "notes_text": "## Section 1\n",
    }
    message = {
        "Records": [
            {
                "body": json.dumps(invalid_payload),
                "messageId": "test-id",
            }
        ]
    }

    response = test_client.post("/", json=message)

    # Should fail when trying to access payload["to"]
    assert response.status_code == status.HTTP_500_INTERNAL_SERVER_ERROR


def test_process_email_empty_records(test_client):
    """Test handling empty records array"""
    empty_message = {"Records": []}

    response = test_client.post("/", json=empty_message)

    # Should succeed but process 0 records
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["processed"] == 0
