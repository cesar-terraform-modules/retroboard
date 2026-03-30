#!/usr/bin/env bash
set -euo pipefail

# Bootstrap S3 + DynamoDB state backend for retroboard StackGen demo.
# Usage: ./bootstrap-state-backend.sh [region]
# Requires: aws cli authenticated with sufficient permissions.

REGION="${1:-us-east-1}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="cesar-demo-tfstate-${ACCOUNT_ID}"
LOCK_TABLE="cesar-demo-tfstate-lock"

echo "Account:    ${ACCOUNT_ID}"
echo "Region:     ${REGION}"
echo "Bucket:     ${BUCKET_NAME}"
echo "Lock Table: ${LOCK_TABLE}"
echo ""

# --- S3 Bucket ---
if aws s3api head-bucket --bucket "${BUCKET_NAME}" 2>/dev/null; then
  echo "Bucket ${BUCKET_NAME} already exists, skipping creation."
else
  echo "Creating S3 bucket ${BUCKET_NAME}..."
  if [ "${REGION}" = "us-east-1" ]; then
    aws s3api create-bucket \
      --bucket "${BUCKET_NAME}" \
      --region "${REGION}"
  else
    aws s3api create-bucket \
      --bucket "${BUCKET_NAME}" \
      --region "${REGION}" \
      --create-bucket-configuration LocationConstraint="${REGION}"
  fi

  echo "Enabling versioning..."
  aws s3api put-bucket-versioning \
    --bucket "${BUCKET_NAME}" \
    --versioning-configuration Status=Enabled

  echo "Enabling server-side encryption (AES256)..."
  aws s3api put-bucket-encryption \
    --bucket "${BUCKET_NAME}" \
    --server-side-encryption-configuration '{
      "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
    }'

  echo "Blocking all public access..."
  aws s3api put-public-access-block \
    --bucket "${BUCKET_NAME}" \
    --public-access-block-configuration \
      BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

  echo "Bucket created."
fi

# --- DynamoDB Lock Table ---
if aws dynamodb describe-table --table-name "${LOCK_TABLE}" --region "${REGION}" >/dev/null 2>&1; then
  echo "DynamoDB table ${LOCK_TABLE} already exists, skipping creation."
else
  echo "Creating DynamoDB table ${LOCK_TABLE}..."
  aws dynamodb create-table \
    --table-name "${LOCK_TABLE}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "${REGION}" \
    --tags Key=Project,Value=cesar-demo Key=ManagedBy,Value=bootstrap

  echo "Waiting for table to become active..."
  aws dynamodb wait table-exists --table-name "${LOCK_TABLE}" --region "${REGION}"
  echo "Table created."
fi

echo ""
echo "State backend ready. Use the following in your Terraform backend config:"
echo ""
echo "  terraform {"
echo "    backend \"s3\" {"
echo "      bucket         = \"${BUCKET_NAME}\""
echo "      dynamodb_table = \"${LOCK_TABLE}\""
echo "      region         = \"${REGION}\""
echo "      encrypt        = true"
echo "      key            = \"<appstack-key>.tfstate\""
echo "    }"
echo "  }"
echo ""
echo "State keys:"
echo "  core-infra/network-foundation.tfstate"
echo "  retroboard/data.tfstate"
echo "  retroboard/messaging.tfstate"
echo "  retroboard/compute.tfstate"
