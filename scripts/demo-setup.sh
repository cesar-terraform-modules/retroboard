#!/usr/bin/env bash
set -euo pipefail

# StackGen Demo Setup Script
# Run this BEFORE the demo to ensure the environment is clean and ready.
# Simulates what the "platform engineering team" has pre-provisioned.
# Requires: aws cli (authenticated), claude cli, docker

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
STATE_BUCKET="cesar-demo-tfstate-${ACCOUNT_ID}"
ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo "============================================="
echo "  StackGen Demo Setup (Platform Team Side)"
echo "============================================="
echo "Account:  ${ACCOUNT_ID}"
echo "Region:   ${REGION}"
echo ""

# --- 1. Verify prerequisites ---
echo "[1/7] Verifying prerequisites..."
aws sts get-caller-identity --query Arn --output text
docker info >/dev/null 2>&1 || { echo "ERROR: Docker not running"; exit 1; }
echo "  AWS + Docker OK"
echo ""

# --- 2. Ensure state backend exists ---
echo "[2/7] Checking state backend..."
if aws s3api head-bucket --bucket "${STATE_BUCKET}" 2>/dev/null; then
  echo "  State bucket exists: ${STATE_BUCKET}"
else
  echo "  Creating state bucket..."
  "${SCRIPT_DIR}/bootstrap-state-backend.sh" "${REGION}"
fi
echo ""

# --- 3. Verify core networking (platform team infra) ---
echo "[3/7] Checking core networking..."
VPC_COUNT=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Project,Values=retroboard" "Name=tag:Environment,Values=dev" \
  --query 'Vpcs | length(@)' --output text 2>/dev/null || echo "0")
if [ "${VPC_COUNT}" -gt 0 ]; then
  echo "  Core networking applied (VPC found)"
else
  echo "  Applying core networking (network-foundation)..."
  echo "  This creates VPC, subnets, NAT gateway (~2-3 min)..."
  claude --print -p "
Using the StackGen user MCP, apply the network-foundation appstack in the
cesar-demo-core-infra project (project_id: 0c40a4fa-1f03-427c-8912-d0527ae991f5).
Use appstack_id 82936fc4-aec5-4e8a-a44a-8b0705f90f03, topology_id same as appstack_id.
Action type: Apply, environment: dev.
Wait for completion and show the result.
" 2>&1 | tail -5
fi
echo ""

# --- 4. Clean up previous demo appstacks ---
echo "[4/7] Checking for leftover demo appstacks..."
claude --print -p "
Using the StackGen user MCP, list all appstacks in the cesar-retroboard-demo
project (project_id: 32f41853-b8b2-4cf8-ba03-61604521e10c).
Just list their names -- do NOT delete or destroy anything.
" 2>/dev/null | grep -E "retroboard-|No appstacks" || echo "  (Could not check)"
echo ""
echo "  If old appstacks exist with applied resources, run ./scripts/demo-teardown.sh first"
echo ""

# --- 5. Pre-provision ECR repos via StackGen (platform team creates registry appstack) ---
echo "[5/7] Pre-provisioning ECR repositories via StackGen..."
ECR_EXISTS=$(aws ecr describe-repositories --repository-names "retroboard/api" --region "${REGION}" 2>/dev/null && echo "yes" || echo "no")
if [ "${ECR_EXISTS}" = "yes" ]; then
  echo "  ECR repos already exist"
else
  echo "  Creating retroboard-registry appstack and applying..."
  echo "  (This creates 4 ECR repos via StackGen ~30s)"
  claude --print -p "
Using the StackGen user MCP, check if a retroboard-registry appstack exists in
the cesar-retroboard-demo project (project_id: 32f41853-b8b2-4cf8-ba03-61604521e10c).

If it doesn't exist, create it (cloud_provider: aws, description: ECR container registries).
Then add 4 ECR repository resources (crb-ecr-repository, template_id: 572c024e-8397-495b-a968-5fd8f39f1290)
with identifiers: ecr_api, ecr_app, ecr_email_summary, ecr_notification.

Configure each with: image_tag_mutable=true, force_delete=true, tags=local.tags.
Repository names: retroboard/api, retroboard/app, retroboard/email-summary, retroboard/notification-service.

Add TF locals for tags (Project=var.project, Environment=var.environment, ManagedBy=stackgen),
an AWS provider (region=var.aws_region), and variables for aws_region (default us-east-1),
project (default retroboard), environment (default dev).

Create a dev environment profile with S3 backend:
bucket=cesar-demo-tfstate-${ACCOUNT_ID}, key=retroboard/registry.tfstate,
region=us-east-1, dynamodb_table=cesar-demo-tfstate-lock.

Then apply it to the dev environment. Wait for completion.
" 2>&1 | tail -10
fi
echo ""

# --- 6. Pre-build and push container images ---
echo "[6/7] Building and pushing container images..."
echo "  This avoids Docker build time during the demo (~2-3 min)"
aws ecr get-login-password --region "${REGION}" | \
  docker login --username AWS --password-stdin "${ECR_REGISTRY}" 2>/dev/null

# Get ALB DNS if it exists (for frontend build arg), otherwise use placeholder
ALB_DNS=$(aws elbv2 describe-load-balancers --names retroboard-dev-alb \
  --query 'LoadBalancers[0].DNSName' --output text 2>/dev/null || echo "PLACEHOLDER")

# Build API
echo "  Building retroboard/api..."
docker build --platform linux/amd64 -q \
  -t "${ECR_REGISTRY}/retroboard/api:latest" \
  "${REPO_DIR}/functions/api" >/dev/null 2>&1
docker push -q "${ECR_REGISTRY}/retroboard/api:latest" >/dev/null 2>&1
echo "    pushed"

# Build App (with ALB URL if available -- will be rebuilt during demo if ALB changes)
echo "  Building retroboard/app..."
docker build --platform linux/amd64 -q \
  --build-arg NEXT_PUBLIC_API_HOST_URL="http://${ALB_DNS}" \
  -t "${ECR_REGISTRY}/retroboard/app:latest" \
  "${REPO_DIR}/app" >/dev/null 2>&1
docker push -q "${ECR_REGISTRY}/retroboard/app:latest" >/dev/null 2>&1
echo "    pushed (NOTE: frontend will need rebuild after ALB is created)"

# Build email-summary
echo "  Building retroboard/email-summary..."
docker build --platform linux/amd64 -q \
  -t "${ECR_REGISTRY}/retroboard/email-summary:latest" \
  "${REPO_DIR}/functions/email-summary" >/dev/null 2>&1
docker push -q "${ECR_REGISTRY}/retroboard/email-summary:latest" >/dev/null 2>&1
echo "    pushed"

# Build notification-service
echo "  Building retroboard/notification-service..."
docker build --platform linux/amd64 -q \
  -t "${ECR_REGISTRY}/retroboard/notification-service:latest" \
  "${REPO_DIR}/functions/notification-service" >/dev/null 2>&1
docker push -q "${ECR_REGISTRY}/retroboard/notification-service:latest" >/dev/null 2>&1
echo "    pushed"
echo ""

# --- 7. Summary ---
echo "[7/7] Cleaning up stale DynamoDB lock entries..."
for KEY in \
  "retroboard/data.tfstate" \
  "retroboard/messaging.tfstate" \
  "retroboard/registry.tfstate" \
  "retroboard/compute.tfstate"; do
  aws dynamodb delete-item --table-name cesar-demo-tfstate-lock \
    --key "{\"LockID\": {\"S\": \"${STATE_BUCKET}/${KEY}-md5\"}}" 2>/dev/null || true
  aws dynamodb delete-item --table-name cesar-demo-tfstate-lock \
    --key "{\"LockID\": {\"S\": \"${STATE_BUCKET}/${KEY}\"}}" 2>/dev/null || true
done
echo "  Done"
echo ""

echo "============================================="
echo "  Setup Complete -- Ready for Demo"
echo "============================================="
echo ""
echo "Platform team has pre-provisioned:"
echo "  - VPC + subnets + NAT gateway (network-foundation)"
echo "  - ECR repositories (4 repos)"
echo "  - Container images (pre-built and pushed)"
echo "  - S3 state backend + DynamoDB lock table"
echo "  - StackGen project, modules, policies, AWS credentials"
echo ""
echo "The developer demo starts from a clean slate in the"
echo "cesar-retroboard-demo project with NO appstacks."
echo ""
echo "During the demo, the developer will only need to:"
echo "  1. Describe their app to the AI"
echo "  2. Let the AI create appstacks, add resources, configure, plan, apply"
echo "  3. Rebuild the frontend image with the real ALB URL (one docker command)"
echo "  4. Open the app in a browser"
echo ""
echo "Expected demo apply times (with pre-built images):"
echo "  - retroboard-data:      ~1 min"
echo "  - retroboard-messaging: ~10 sec"
echo "  - retroboard-compute:   ~2 min (ALB + ECS)"
echo "  Total: ~3-4 min of apply time"
echo ""
