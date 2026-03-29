#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
TABLE_NAME="${DYNAMODB_TABLE_NAME:-boards}"
QUEUE_NAME="${SQS_QUEUE_NAME:-retroboard-emails}"
TOPIC_NAME="${SNS_TOPIC_NAME:-retroboard-alerts}"
SENDER_EMAIL="${SES_SENDER_EMAIL_ADDRESS:-noreply@example.com}"
TEMPLATE_NAME="${TEMPLATE_NAME:-retroboard-summary}"

if ! command -v aws >/dev/null 2>&1; then
  echo "aws CLI is required" >&2
  exit 1
fi

echo "Using region: ${AWS_REGION}"

if aws dynamodb describe-table --table-name "${TABLE_NAME}" --region "${AWS_REGION}" >/dev/null 2>&1; then
  echo "DynamoDB table exists: ${TABLE_NAME}"
else
  echo "Creating DynamoDB table: ${TABLE_NAME}"
  aws dynamodb create-table \
    --table-name "${TABLE_NAME}" \
    --attribute-definitions AttributeName=id,AttributeType=S \
    --key-schema AttributeName=id,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "${AWS_REGION}" >/dev/null
fi

QUEUE_URL="$(aws sqs get-queue-url --queue-name "${QUEUE_NAME}" --region "${AWS_REGION}" --query 'QueueUrl' --output text 2>/dev/null || true)"
if [[ -z "${QUEUE_URL}" || "${QUEUE_URL}" == "None" ]]; then
  echo "Creating SQS queue: ${QUEUE_NAME}"
  QUEUE_URL="$(aws sqs create-queue --queue-name "${QUEUE_NAME}" --region "${AWS_REGION}" --query 'QueueUrl' --output text)"
else
  echo "SQS queue exists: ${QUEUE_NAME}"
fi

echo "Ensuring SNS topic: ${TOPIC_NAME}"
TOPIC_ARN="$(aws sns create-topic --name "${TOPIC_NAME}" --region "${AWS_REGION}" --query 'TopicArn' --output text)"

echo "Ensuring SES identity: ${SENDER_EMAIL}"
aws ses verify-email-identity --email-address "${SENDER_EMAIL}" --region "${AWS_REGION}" >/dev/null || true

read -r -d '' TEMPLATE_JSON <<'JSON' || true
{
  "Template": {
    "TemplateName": "__TEMPLATE_NAME__",
    "SubjectPart": "Retroboard Summary",
    "HtmlPart": "<h2>Retroboard Summary</h2><p>You have new retroboard content.</p><pre>{{board}}</pre>",
    "TextPart": "Retroboard Summary\n\n{{board}}"
  }
}
JSON

TEMPLATE_JSON="${TEMPLATE_JSON/__TEMPLATE_NAME__/${TEMPLATE_NAME}}"

if aws ses get-template --template-name "${TEMPLATE_NAME}" --region "${AWS_REGION}" >/dev/null 2>&1; then
  echo "Updating SES template: ${TEMPLATE_NAME}"
  aws ses update-template --cli-input-json "${TEMPLATE_JSON}" --region "${AWS_REGION}" >/dev/null
else
  echo "Creating SES template: ${TEMPLATE_NAME}"
  aws ses create-template --cli-input-json "${TEMPLATE_JSON}" --region "${AWS_REGION}" >/dev/null
fi

echo "Done."
echo "QUEUE_URL=${QUEUE_URL}"
echo "TOPIC_ARN=${TOPIC_ARN}"
