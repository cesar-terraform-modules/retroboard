import logging
import os
import boto3
from botocore.exceptions import BotoCoreError, ClientError, NoCredentialsError
from typing import Final

logger = logging.getLogger(__name__)

AWS_REGION: Final[str] = os.environ.get("AWS_REGION", "us-east-1")
AWS_ENDPOINT_URL = os.environ.get("AWS_ENDPOINT_URL")

# Get AWS Account ID from environment variable if available, otherwise use STS.
# Fall back to a placeholder when creds are missing so the process can still start
# (e.g. Shipyard preview without AWS wired up yet).
_PLACEHOLDER_ACCOUNT_ID = "000000000000"


def _resolve_aws_account_id() -> str:
    if os.environ.get("AWS_ACCOUNT_ID"):
        return os.environ["AWS_ACCOUNT_ID"]

    sts_client_kwargs = {"region_name": AWS_REGION}
    if AWS_ENDPOINT_URL:
        sts_client_kwargs["endpoint_url"] = AWS_ENDPOINT_URL

    try:
        sts_client = boto3.client("sts", **sts_client_kwargs)
        return sts_client.get_caller_identity()["Account"]
    except (NoCredentialsError, BotoCoreError, ClientError) as exc:
        logger.warning(
            "Unable to resolve AWS account ID via STS (%s); using placeholder %s",
            exc,
            _PLACEHOLDER_ACCOUNT_ID,
        )
        return _PLACEHOLDER_ACCOUNT_ID


AWS_ACCOUNT_ID: Final[str] = _resolve_aws_account_id()

DYNAMODB_TABLE_NAME: Final[str] = os.environ.get("DYNAMODB_TABLE_NAME", "boards")
EMAILS_SQS_QUEUE: Final[str] = os.environ.get("EMAILS_SQS_QUEUE", "retroboard-emails")
SLACK_ALERTS_SNS_TOPIC: Final[str] = os.environ.get(
    "SLACK_ALERTS_SNS_TOPIC", "retroboard-alerts"
)

SNS_TOPIC_SLACK_ALERTS_ARN: Final[str] = (
    f"arn:aws:sns:{AWS_REGION}:{AWS_ACCOUNT_ID}:{SLACK_ALERTS_SNS_TOPIC}"
)
SQS_SEND_EMAIL_QUEUE_URL: Final[str] = (
    f"https://sqs.{AWS_REGION}.amazonaws.com/{AWS_ACCOUNT_ID}/{EMAILS_SQS_QUEUE}"
)

# Default to localhost so the service can boot without CORS wiring
# (e.g. Shipyard preview). main.py always appends http://localhost:3000.
CORS_ALLOWED_ORIGINS: Final[str] = os.environ.get(
    "CORS_ALLOWED_ORIGINS", "http://localhost:3000"
)
