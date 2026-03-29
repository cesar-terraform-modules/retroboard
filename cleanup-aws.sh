#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
TABLE_NAME="${DYNAMODB_TABLE_NAME:-boards}"
QUEUE_NAME="${SQS_QUEUE_NAME:-retroboard-emails}"
TOPIC_NAME="${SNS_TOPIC_NAME:-retroboard-alerts}"
TEMPLATE_NAME="${TEMPLATE_NAME:-retroboard-summary}"

if ! command -v aws >/dev/null 2>&1; then
  echo "aws CLI is required" >&2
  exit 1
fi

if [[ "${RETROBOARD_FORCE_DESTROY:-}" != "1" ]]; then
  echo "Refusing to destroy AWS resources without confirmation."
  echo "Re-run with: RETROBOARD_FORCE_DESTROY=1 ./cleanup-aws.sh"
  exit 1
fi

echo "Cleaning up retroboard AWS resources in region ${AWS_REGION}..."

# Delete SES template (if exists)
if aws ses get-template --template-name "${TEMPLATE_NAME}" --region "${AWS_REGION}" >/dev/null 2>&1; then
  echo "Deleting SES template: ${TEMPLATE_NAME}"
  aws ses delete-template --template-name "${TEMPLATE_NAME}" --region "${AWS_REGION}" >/dev/null
else
  echo "SES template not found: ${TEMPLATE_NAME}"
fi

# Delete SNS topic (if exists)
TOPIC_ARN="$(aws sns list-topics --region "${AWS_REGION}" --query "Topics[?ends_with(TopicArn, ':${TOPIC_NAME}')].TopicArn | [0]" --output text 2>/dev/null || true)"
if [[ -n "${TOPIC_ARN}" && "${TOPIC_ARN}" != "None" ]]; then
  echo "Deleting SNS topic: ${TOPIC_ARN}"
  aws sns delete-topic --topic-arn "${TOPIC_ARN}" --region "${AWS_REGION}" >/dev/null
else
  echo "SNS topic not found: ${TOPIC_NAME}"
fi

# Delete SQS queue (if exists)
QUEUE_URL="$(aws sqs get-queue-url --queue-name "${QUEUE_NAME}" --region "${AWS_REGION}" --query 'QueueUrl' --output text 2>/dev/null || true)"
if [[ -n "${QUEUE_URL}" && "${QUEUE_URL}" != "None" ]]; then
  echo "Deleting SQS queue: ${QUEUE_URL}"
  aws sqs delete-queue --queue-url "${QUEUE_URL}" --region "${AWS_REGION}" >/dev/null
else
  echo "SQS queue not found: ${QUEUE_NAME}"
fi

# Delete DynamoDB table (if exists)
if aws dynamodb describe-table --table-name "${TABLE_NAME}" --region "${AWS_REGION}" >/dev/null 2>&1; then
  echo "Deleting DynamoDB table: ${TABLE_NAME}"
  aws dynamodb delete-table --table-name "${TABLE_NAME}" --region "${AWS_REGION}" >/dev/null
else
  echo "DynamoDB table not found: ${TABLE_NAME}"
fi

echo "Cleanup requested. Some resources may take a short time to fully disappear."
