import os
import boto3
from typing import Final

AWS_REGION: Final[str] = os.environ["AWS_REGION"]
AWS_ENDPOINT_URL = os.environ.get("AWS_ENDPOINT_URL")

# Get AWS Account ID from environment variable if available, otherwise use STS
# This allows LocalStack to work without STS service enabled
if "AWS_ACCOUNT_ID" in os.environ:
    _aws_account_id = os.environ["AWS_ACCOUNT_ID"]
else:
    # Configure STS client with region and endpoint_url for LocalStack
    sts_client_kwargs = {"region_name": AWS_REGION}
    if AWS_ENDPOINT_URL:
        sts_client_kwargs["endpoint_url"] = AWS_ENDPOINT_URL

    sts_client = boto3.client("sts", **sts_client_kwargs)
    _aws_account_id = sts_client.get_caller_identity()["Account"]

AWS_ACCOUNT_ID: Final[str] = _aws_account_id

DYNAMODB_TABLE_NAME: Final[str] = "boards"
EMAILS_SQS_QUEUE: Final[str] = "retroboard-emails"
SLACK_ALERTS_SNS_TOPIC: Final[str] = "retroboard-alerts"

SNS_TOPIC_SLACK_ALERTS_ARN: Final[str] = (
    f"arn:aws:sns:{AWS_REGION}:{AWS_ACCOUNT_ID}:{SLACK_ALERTS_SNS_TOPIC}"
)
SQS_SEND_EMAIL_QUEUE_URL: Final[str] = (
    f"https://sqs.{AWS_REGION}.amazonaws.com/{AWS_ACCOUNT_ID}/{EMAILS_SQS_QUEUE}"
)

CORS_ALLOWED_ORIGINS: Final[str] = os.environ["CORS_ALLOWED_ORIGINS"]
