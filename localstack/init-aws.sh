#!/bin/bash
# Runs on every LocalStack start (ready.d hook). Idempotent: resources match
# tests/integration/helpers/localstack_init.py and functions/api/env.py.
set -euo pipefail

awslocal dynamodb describe-table --table-name boards >/dev/null 2>&1 ||
  awslocal dynamodb create-table --table-name boards \
    --attribute-definitions AttributeName=board_id,AttributeType=S AttributeName=sk,AttributeType=S \
    --key-schema AttributeName=board_id,KeyType=HASH AttributeName=sk,KeyType=RANGE \
    --billing-mode PAY_PER_REQUEST >/dev/null
awslocal dynamodb wait table-exists --table-name boards

awslocal sqs create-queue --queue-name retroboard-emails >/dev/null
awslocal sns create-topic --name retroboard-alerts >/dev/null
awslocal ses verify-email-identity --email-address noreply@example.com

echo "retroboard resources ready"
