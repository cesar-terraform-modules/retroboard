#!/bin/bash

# Initialize LocalStack resources for local development
# This script creates the necessary DynamoDB tables, SQS queues, and SNS topics

echo "Initializing LocalStack resources..."

# Set LocalStack endpoint
ENDPOINT="http://localhost:4566"
REGION="us-east-1"

# Create DynamoDB table
echo "Creating DynamoDB table..."
aws --endpoint-url=$ENDPOINT dynamodb create-table \
  --table-name boards \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
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

