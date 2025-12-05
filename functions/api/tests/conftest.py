import os
import pytest
from unittest.mock import Mock, patch, MagicMock
from moto import mock_aws
import boto3
from fastapi.testclient import TestClient
from datetime import datetime

# Set environment variables before importing modules
os.environ["AWS_REGION"] = "us-east-1"
os.environ["AWS_ACCOUNT_ID"] = "123456789012"
os.environ["CORS_ALLOWED_ORIGINS"] = "http://localhost:3000"
os.environ["DYNAMODB_TABLE_NAME"] = "boards"

# Mock STS before importing env.py
mock_sts_client = MagicMock()
mock_sts_client.get_caller_identity.return_value = {"Account": "123456789012"}

# Patch boto3.client to return mock STS for sts service
original_boto3_client = boto3.client


def mock_boto3_client(service, **kwargs):
    if service == "sts":
        return mock_sts_client
    return original_boto3_client(service, **kwargs)


boto3.client = mock_boto3_client

# Now import modules
from repo import BoardRepo, initialize_db
from models import Board, Note, BoardBase, NoteBase

# Restore after imports
boto3.client = original_boto3_client


@pytest.fixture(scope="function")
def aws_credentials():
    """Mocked AWS Credentials for moto"""
    os.environ["AWS_ACCESS_KEY_ID"] = "testing"
    os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
    os.environ["AWS_SECURITY_TOKEN"] = "testing"
    os.environ["AWS_SESSION_TOKEN"] = "testing"
    os.environ["AWS_DEFAULT_REGION"] = "us-east-1"


@pytest.fixture
def aws_mocks(aws_credentials):
    """Set up all AWS service mocks together"""
    with mock_aws():
        # Set up DynamoDB
        dynamodb = boto3.resource("dynamodb", region_name="us-east-1")
        table = dynamodb.create_table(
            TableName="boards",
            KeySchema=[
                {"AttributeName": "board_id", "KeyType": "HASH"},
                {"AttributeName": "sk", "KeyType": "RANGE"},
            ],
            AttributeDefinitions=[
                {"AttributeName": "board_id", "AttributeType": "S"},
                {"AttributeName": "sk", "AttributeType": "S"},
            ],
            BillingMode="PAY_PER_REQUEST",
        )

        # Set up SNS
        sns_client = boto3.client("sns", region_name="us-east-1")
        topic_arn = sns_client.create_topic(Name="retroboard-alerts")["TopicArn"]
        os.environ["SNS_TOPIC_SLACK_ALERTS_ARN"] = topic_arn

        # Set up SQS
        sqs_client = boto3.client("sqs", region_name="us-east-1")
        queue_url = sqs_client.create_queue(QueueName="retroboard-emails")["QueueUrl"]
        os.environ["SQS_SEND_EMAIL_QUEUE_URL"] = queue_url

        yield {
            "dynamodb": dynamodb,
            "table": table,
            "sns_client": sns_client,
            "sqs_client": sqs_client,
        }


@pytest.fixture
def test_client(aws_mocks):
    """Create a test client with mocked AWS services"""
    # Import main module
    import main

    # Create fresh db and repo instances
    test_db = initialize_db()
    test_repo = BoardRepo(test_db)

    # Patch the module-level clients and db/repo
    with patch.object(main, "sns_client", aws_mocks["sns_client"]), patch.object(
        main, "sqs_client", aws_mocks["sqs_client"]
    ), patch.object(main, "db", test_db), patch.object(main, "repo", test_repo):
        client = TestClient(main.app)
        yield client


@pytest.fixture
def sample_board_data():
    """Sample board data for testing"""
    return {
        "name": "Test Board",
        "section_details": ["What went well", "What to improve"],
    }


@pytest.fixture
def sample_note_data():
    """Sample note data for testing"""
    return {
        "section_number": 1,
        "text": "This is a test note",
        "votes": 0,
    }


@pytest.fixture
def created_board(test_client, sample_board_data):
    """Create a board and return it"""
    response = test_client.post("/boards", json=sample_board_data)
    assert response.status_code == 201
    return response.json()


@pytest.fixture
def created_note(test_client, created_board, sample_note_data):
    """Create a note and return it"""
    response = test_client.post(
        f"/boards/{created_board['id']}/notes", json=sample_note_data
    )
    assert response.status_code == 201
    return response.json()
