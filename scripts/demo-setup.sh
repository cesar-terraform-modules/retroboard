#!/usr/bin/env bash
set -euo pipefail

# StackGen Demo Setup Script
# Run this BEFORE the demo to ensure the environment is clean and ready.
# Simulates what the "platform engineering team" has pre-provisioned.
# Requires: aws cli (authenticated), claude cli, docker
#
# Usage:
#   ./scripts/demo-setup.sh              # defaults to "staging"
#   ./scripts/demo-setup.sh staging      # stage.dev.stackgen.com
#   ./scripts/demo-setup.sh main         # main.dev.stackgen.com

STACKGEN_ENV="${1:-staging}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
STATE_BUCKET="cesar-demo-tfstate-${ACCOUNT_ID}"
ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

# --- Environment-specific IDs ---
if [ "${STACKGEN_ENV}" = "main" ]; then
  STACKGEN_URL="main.dev.stackgen.com"
  MCP_ADMIN="stackgen-main-dev-admin"
  MCP_USER="stackgen-main-dev-user"
  CORE_INFRA_PROJECT_ID="0c40a4fa-1f03-427c-8912-d0527ae991f5"
  RETROBOARD_PROJECT_ID="32f41853-b8b2-4cf8-ba03-61604521e10c"
  NETWORK_APPSTACK_ID="82936fc4-aec5-4e8a-a44a-8b0705f90f03"
  ECR_TEMPLATE_ID="572c024e-8397-495b-a968-5fd8f39f1290"
elif [ "${STACKGEN_ENV}" = "staging" ]; then
  STACKGEN_URL="stage.dev.stackgen.com"
  MCP_ADMIN="stackgen-stage-dev-admin"
  MCP_USER="stackgen-stage-dev-user"
  CORE_INFRA_PROJECT_ID="463a9720-a15e-417b-b842-9e2ee12e4e33"
  RETROBOARD_PROJECT_ID="7260e64b-6a0a-474d-926b-214b2d91391a"
  NETWORK_APPSTACK_ID=""  # Will be created if needed
  ECR_TEMPLATE_ID="73a093bf-2407-4ff8-8f78-69e72c79d0e6"
else
  echo "ERROR: Unknown environment '${STACKGEN_ENV}'. Use 'main' or 'staging'."
  exit 1
fi

echo "============================================="
echo "  StackGen Demo Setup (Platform Team Side)"
echo "============================================="
echo "StackGen:  ${STACKGEN_URL}"
echo "MCP:       ${MCP_USER}"
echo "Account:   ${ACCOUNT_ID}"
echo "Region:    ${REGION}"
echo "Core-Infra Project: ${CORE_INFRA_PROJECT_ID}"
echo "Retroboard Project: ${RETROBOARD_PROJECT_ID}"
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
  echo "  Core networking NOT found."
  echo "  You need to create and apply the network-foundation appstack."
  echo ""
  echo "  In Claude Code, use the ${MCP_USER} MCP tools:"
  echo ""
  echo "  1. Create appstack 'network-foundation' in cesar-demo-core-infra"
  echo "     project_id: ${CORE_INFRA_PROJECT_ID}"
  echo ""
  echo "  2. Add crb-networking-basics resource, configure with:"
  echo "     cidr=var.vpc_cidr, az_count=var.az_count, create_nat_gateway=true,"
  echo "     enable_flow_logs=false, tags=local.tags"
  echo ""
  echo "  3. Add variables (aws_region, vpc_cidr=10.0.0.0/16, az_count=2,"
  echo "     project=retroboard, environment=dev), locals (tags), provider (aws)"
  echo ""
  echo "  4. Create dev env profile with S3 backend:"
  echo "     bucket=${STATE_BUCKET}, key=core-infra/network-foundation.tfstate"
  echo ""
  echo "  5. Apply to dev environment (~2-3 min for NAT gateway)"
  echo ""
  echo "  Or run this prompt in Claude Code:"
  echo '  "Using the '${MCP_USER}' tools, create a network-foundation appstack'
  echo '   in project '${CORE_INFRA_PROJECT_ID}' with a VPC (10.0.0.0/16, 2 AZs,'
  echo '   NAT gateway, no flow logs). Add variables, locals, provider, dev env'
  echo '   profile with S3 backend (bucket '${STATE_BUCKET}','
  echo '   key core-infra/network-foundation.tfstate), then apply."'
  echo ""
fi
echo ""

# --- 4. Clean up previous demo appstacks ---
echo "[4/7] Checking for leftover demo appstacks..."
claude --print -p "
Using the ${MCP_USER} MCP tools, list all appstacks in project
${RETROBOARD_PROJECT_ID}. Just list their names -- do NOT delete or destroy anything.
" 2>/dev/null | grep -E "retroboard-|No appstacks|name" | head -10 || echo "  (Could not check)"
echo ""
echo "  If old appstacks exist with applied resources, run:"
echo "  ./scripts/demo-teardown.sh ${STACKGEN_ENV}"
echo ""

# --- 5. Pre-provision ECR repos via StackGen ---
echo "[5/7] Pre-provisioning ECR repositories via StackGen..."
ECR_EXISTS=$(aws ecr describe-repositories --repository-names "retroboard/api" --region "${REGION}" 2>/dev/null && echo "yes" || echo "no")
if [ "${ECR_EXISTS}" = "yes" ]; then
  echo "  ECR repos already exist"
else
  echo "  Creating retroboard-registry appstack and applying..."
  echo "  (This creates 4 ECR repos via StackGen ~30s)"
  claude --print -p "
Using the ${MCP_USER} MCP tools, check if a retroboard-registry appstack exists in
project ${RETROBOARD_PROJECT_ID}.

If it doesn't exist, create it (cloud_provider: aws, description: ECR container registries).
Then add 4 ECR repository resources (crb-ecr-repository, template_id: ${ECR_TEMPLATE_ID})
with identifiers: ecr_api, ecr_app, ecr_email_summary, ecr_notification.

Configure each with: image_tag_mutable=true, force_delete=true, tags=local.tags.
Repository names: retroboard/api, retroboard/app, retroboard/email-summary, retroboard/notification-service.

Add TF locals for tags (Project=var.project, Environment=var.environment, ManagedBy=stackgen),
an AWS provider (region=var.aws_region), and variables for aws_region (default us-east-1),
project (default retroboard), environment (default dev).

Create a dev environment profile with S3 backend:
bucket=${STATE_BUCKET}, key=retroboard/registry.tfstate,
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

# --- 7. Clean up stale locks ---
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
echo "StackGen instance: ${STACKGEN_URL}"
echo "MCP tools prefix:  ${MCP_USER}"
echo ""
echo "Platform team has pre-provisioned:"
echo "  - VPC + subnets + NAT gateway (network-foundation)"
echo "  - ECR repositories (4 repos)"
echo "  - Container images (pre-built and pushed)"
echo "  - S3 state backend + DynamoDB lock table"
echo "  - StackGen project, modules, policies, AWS credentials"
echo ""
echo "During the demo, the developer will only need to:"
echo "  1. Describe their app to the AI"
echo "  2. Let the AI create appstacks, add resources, configure, plan, apply"
echo "  3. Rebuild the frontend image with the real ALB URL"
echo "  4. Open the app in a browser"
echo ""
