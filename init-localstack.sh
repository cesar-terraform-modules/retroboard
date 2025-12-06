#!/bin/bash

# Initialize LocalStack resources for local development
# This script creates the necessary DynamoDB tables, SQS queues, and SNS topics

echo "Initializing LocalStack resources..."

# Set LocalStack endpoint
ENDPOINT="http://localhost:4566"
REGION="us-east-1"
# Provide default credentials for LocalStack if none are set
export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}"

# Ensure DynamoDB table exists with correct schema (board_id + sk)
echo "Creating DynamoDB table..."
# Remove existing table to guarantee the correct key schema for tests
aws --endpoint-url=$ENDPOINT dynamodb delete-table \
  --table-name boards \
  --region $REGION >/dev/null 2>&1 || true

aws --endpoint-url=$ENDPOINT dynamodb create-table \
  --table-name boards \
  --attribute-definitions AttributeName=board_id,AttributeType=S AttributeName=sk,AttributeType=S \
  --key-schema AttributeName=board_id,KeyType=HASH AttributeName=sk,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST \
  --region $REGION

# Create SQS queue
echo "Creating SQS queue..."
aws --endpoint-url=$ENDPOINT sqs create-queue \
  --queue-name retroboard-emails \
  --region $REGION

# Create SNS topic
echo "Creating SNS topic..."
aws --endpoint-url=$ENDPOINT sns create-topic \
  --name retroboard-alerts \
  --region $REGION

# Verify SES email (for local testing)
echo "Verifying SES email address..."
aws --endpoint-url=$ENDPOINT ses verify-email-identity \
  --email-address noreply@example.com \
  --region $REGION

echo "LocalStack resources initialized successfully!"
echo ""
echo "You can now start the services with: docker-compose up"

