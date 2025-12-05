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

    # Set up boto3 clients
    dynamodb = boto3.client("dynamodb", endpoint_url=endpoint_url, region_name=region)
    sqs = boto3.client("sqs", endpoint_url=endpoint_url, region_name=region)
    sns = boto3.client("sns", endpoint_url=endpoint_url, region_name=region)
    ses = boto3.client("ses", endpoint_url=endpoint_url, region_name=region)

    # Create DynamoDB table
    try:
        table_response = dynamodb.create_table(
            TableName="boards",
            AttributeDefinitions=[{"AttributeName": "id", "AttributeType": "S"}],
            KeySchema=[{"AttributeName": "id", "KeyType": "HASH"}],
            BillingMode="PAY_PER_REQUEST",
        )
        resources["dynamodb_table"] = table_response["TableDescription"]["TableName"]
        print(f"Created DynamoDB table: {resources['dynamodb_table']}")
    except ClientError as e:
        if e.response["Error"]["Code"] == "ResourceInUseException":
            print("DynamoDB table already exists")
            resources["dynamodb_table"] = "boards"
        else:
            raise

    # Create SQS queue
    try:
        queue_response = sqs.create_queue(QueueName="retroboard-emails")
        resources["sqs_queue_url"] = queue_response["QueueUrl"]
        print(f"Created SQS queue: {resources['sqs_queue_url']}")
    except ClientError as e:
        if e.response["Error"]["Code"] == "QueueAlreadyExists":
            # Get existing queue URL
            queue_response = sqs.get_queue_url(QueueName="retroboard-emails")
            resources["sqs_queue_url"] = queue_response["QueueUrl"]
            print(f"SQS queue already exists: {resources['sqs_queue_url']}")
        else:
            raise

    # Create SNS topic
    try:
        topic_response = sns.create_topic(Name="retroboard-alerts")
        resources["sns_topic_arn"] = topic_response["TopicArn"]
        print(f"Created SNS topic: {resources['sns_topic_arn']}")
    except ClientError as e:
        if e.response["Error"]["Code"] == "InvalidParameter":
            # Topic might already exist, try to get it
            topics = sns.list_topics()
            for topic_arn in topics.get("Topics", []):
                if "retroboard-alerts" in topic_arn["TopicArn"]:
                    resources["sns_topic_arn"] = topic_arn["TopicArn"]
                    print(f"SNS topic already exists: {resources['sns_topic_arn']}")
                    break
        else:
            raise

    # Verify SES email (for local testing)
    try:
        ses.verify_email_identity(EmailAddress="noreply@example.com")
        resources["ses_email"] = "noreply@example.com"
        print(f"Verified SES email: {resources['ses_email']}")
    except ClientError as e:
        if e.response["Error"]["Code"] == "MessageRejected":
            # Email might already be verified
            resources["ses_email"] = "noreply@example.com"
            print(f"SES email already verified: {resources['ses_email']}")
        else:
            raise

    return resources
