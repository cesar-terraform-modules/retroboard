"""Helper functions to initialize LocalStack resources."""

import boto3
import os
from botocore.exceptions import ClientError


def initialize_localstack_resources(
    endpoint_url: str = "http://localhost:4566",
    region: str = "us-east-1",
) -> dict:
    """
    Initialize LocalStack resources (DynamoDB, SQS, SNS, SES).

    Args:
        endpoint_url: LocalStack endpoint URL
        region: AWS region

    Returns:
        Dictionary with created resource ARNs/URLs
    """
    resources = {}

    # Use provided AWS credentials when available, otherwise fall back to LocalStack-safe defaults
    aws_access_key_id = os.getenv("AWS_ACCESS_KEY_ID", "test")
    aws_secret_access_key = os.getenv("AWS_SECRET_ACCESS_KEY", "test")
    aws_session_token = os.getenv("AWS_SESSION_TOKEN")

    client_kwargs = {
        "endpoint_url": endpoint_url,
        "region_name": region,
        "aws_access_key_id": aws_access_key_id,
        "aws_secret_access_key": aws_secret_access_key,
    }
    if aws_session_token:
        client_kwargs["aws_session_token"] = aws_session_token

    # Set up boto3 clients
    dynamodb = boto3.client("dynamodb", **client_kwargs)
    sqs = boto3.client("sqs", **client_kwargs)
    sns = boto3.client("sns", **client_kwargs)
    ses = boto3.client("ses", **client_kwargs)

    # Create DynamoDB table (idempotent)
    try:
        # Clean up any existing table with incorrect schema to ensure tests run deterministically
        existing_tables = dynamodb.list_tables().get("TableNames", [])
        if "boards" in existing_tables:
            dynamodb.delete_table(TableName="boards")
            dynamodb.get_waiter("table_not_exists").wait(TableName="boards")

        table_response = dynamodb.create_table(
            TableName="boards",
            AttributeDefinitions=[
                {"AttributeName": "board_id", "AttributeType": "S"},
                {"AttributeName": "sk", "AttributeType": "S"},
            ],
            KeySchema=[
                {"AttributeName": "board_id", "KeyType": "HASH"},
                {"AttributeName": "sk", "KeyType": "RANGE"},
            ],
            BillingMode="PAY_PER_REQUEST",
        )
        resources["dynamodb_table"] = table_response["TableDescription"]["TableName"]
        dynamodb.get_waiter("table_exists").wait(TableName="boards")
        print(f"Created DynamoDB table: {resources['dynamodb_table']}")
    except ClientError as e:
        if e.response["Error"]["Code"] == "ResourceInUseException":
            print("DynamoDB table already exists")
            resources["dynamodb_table"] = "boards"
        else:
            raise

    # Create SQS queue (create_queue is idempotent in LocalStack)
    try:
        queue_response = sqs.create_queue(QueueName="retroboard-emails")
        resources["sqs_queue_url"] = queue_response["QueueUrl"]
        print(f"Created/retrieved SQS queue: {resources['sqs_queue_url']}")
    except ClientError as e:
        # If create fails, try to get existing queue
        if e.response["Error"]["Code"] in (
            "QueueAlreadyExists",
            "AWS.SimpleQueueService.QueueAlreadyExists",
        ):
            queue_response = sqs.get_queue_url(QueueName="retroboard-emails")
            resources["sqs_queue_url"] = queue_response["QueueUrl"]
            print(f"SQS queue already exists: {resources['sqs_queue_url']}")
        else:
            raise

    # Create SNS topic (create_topic is idempotent in LocalStack)
    try:
        topic_response = sns.create_topic(Name="retroboard-alerts")
        resources["sns_topic_arn"] = topic_response["TopicArn"]
        print(f"Created/retrieved SNS topic: {resources['sns_topic_arn']}")
    except ClientError as e:
        # If create fails, try to get existing topic
        error_code = e.response["Error"]["Code"]
        if error_code in ("InvalidParameter", "NotFound"):
            # Topic might already exist, try to get it
            topics = sns.list_topics()
            for topic_arn in topics.get("Topics", []):
                if "retroboard-alerts" in topic_arn["TopicArn"]:
                    resources["sns_topic_arn"] = topic_arn["TopicArn"]
                    print(f"SNS topic already exists: {resources['sns_topic_arn']}")
                    break
            else:
                # Topic not found, re-raise the error
                raise
        else:
            raise

    # Verify SES email (for local testing)
    # Note: verify_email_identity is idempotent in LocalStack
    try:
        ses.verify_email_identity(EmailAddress="noreply@example.com")
        resources["ses_email"] = "noreply@example.com"
        print(f"Verified SES email: {resources['ses_email']}")
    except ClientError as e:
        error_code = e.response["Error"]["Code"]
        # Email might already be verified or verification might have failed
        # In LocalStack, this is usually fine - just continue
        if error_code in ("MessageRejected", "InvalidParameter"):
            resources["ses_email"] = "noreply@example.com"
            print(
                f"SES email verification skipped (already verified or not required): {resources['ses_email']}"
            )
        else:
            # For other errors, log but don't fail
            print(
                f"Warning: SES email verification failed with {error_code}, continuing anyway"
            )
            resources["ses_email"] = "noreply@example.com"

    return resources
