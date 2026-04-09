#!/usr/bin/env bash
set -euo pipefail

# StackGen Demo Teardown Script
# Destroys all demo infrastructure to avoid ongoing AWS costs.
# Uses Claude CLI with StackGen MCP to destroy appstacks in reverse dependency order.
#
# Usage:
#   ./scripts/demo-teardown.sh              # defaults to "staging"
#   ./scripts/demo-teardown.sh staging      # stage.dev.stackgen.com
#   ./scripts/demo-teardown.sh main         # main.dev.stackgen.com

STACKGEN_ENV="${1:-staging}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# --- Environment-specific IDs ---
if [ "${STACKGEN_ENV}" = "main" ]; then
  MCP_USER="stackgen-main-dev-user"
  RETROBOARD_PROJECT_ID="32f41853-b8b2-4cf8-ba03-61604521e10c"
elif [ "${STACKGEN_ENV}" = "staging" ]; then
  MCP_USER="stackgen-stage-dev-user"
  RETROBOARD_PROJECT_ID="7260e64b-6a0a-474d-926b-214b2d91391a"
else
  echo "ERROR: Unknown environment '${STACKGEN_ENV}'. Use 'main' or 'staging'."
  exit 1
fi

echo "=== StackGen Demo Teardown (${STACKGEN_ENV}) ==="
echo "MCP:     ${MCP_USER}"
echo "Project: ${RETROBOARD_PROJECT_ID}"
echo "Account: ${ACCOUNT_ID}"
echo ""
echo "This will DESTROY all retroboard demo infrastructure."
echo "Press Ctrl+C to cancel, or Enter to continue..."
read -r

# --- 1. Destroy compute (depends on everything else) ---
echo "[1/5] Destroying retroboard-compute..."
claude --print -p "
Using the ${MCP_USER} MCP tools, find the retroboard-compute appstack in
project ${RETROBOARD_PROJECT_ID}.
Run a Destroy action on it in the dev environment.
Use create_appstack_action_run with action_type 'Destroy'.
Wait for it to complete and show me the result.
" 2>&1 | tail -5
echo ""

# --- 2. Deregister service discovery instances (may block deletes) ---
echo "[2/5] Cleaning up service discovery instances..."
for SVC_ID in $(aws servicediscovery list-services --query 'Services[].Id' --output text 2>/dev/null); do
  for INST_ID in $(aws servicediscovery list-instances --service-id "${SVC_ID}" --query 'Instances[].Id' --output text 2>/dev/null); do
    echo "  Deregistering ${INST_ID} from ${SVC_ID}"
    aws servicediscovery deregister-instance --service-id "${SVC_ID}" --instance-id "${INST_ID}" 2>/dev/null || true
  done
done
sleep 5
echo ""

# --- 3. Destroy registry, data, and messaging (parallel-safe) ---
echo "[3/5] Destroying retroboard-registry, retroboard-data, retroboard-messaging..."
claude --print -p "
Using the ${MCP_USER} MCP tools, find these appstacks in project ${RETROBOARD_PROJECT_ID}:
- retroboard-registry
- retroboard-data
- retroboard-messaging

Run Destroy actions on all of them in the dev environment, in parallel.
Use create_appstack_action_run with action_type 'Destroy' for each.
Wait for all to complete and show results.
" 2>&1 | tail -10
echo ""

# --- 4. Skip network-foundation (platform team owns it) ---
echo "[4/5] Skipping network-foundation -- managed by platform team"
echo "  (To destroy it manually: use StackGen UI or run Destroy on cesar-demo-core-infra)"
echo ""

# --- 5. Clean up state files (retroboard project only) ---
echo "[5/5] Cleaning up state files..."
BUCKET="cesar-demo-tfstate-${ACCOUNT_ID}"
for KEY in \
  "retroboard/data.tfstate" \
  "retroboard/messaging.tfstate" \
  "retroboard/registry.tfstate" \
  "retroboard/compute.tfstate"; do
  echo "  Deleting s3://${BUCKET}/${KEY}"
  aws s3 rm "s3://${BUCKET}/${KEY}" 2>/dev/null || true
  aws dynamodb delete-item --table-name cesar-demo-tfstate-lock \
    --key "{\"LockID\": {\"S\": \"${BUCKET}/${KEY}-md5\"}}" 2>/dev/null || true
  aws dynamodb delete-item --table-name cesar-demo-tfstate-lock \
    --key "{\"LockID\": {\"S\": \"${BUCKET}/${KEY}\"}}" 2>/dev/null || true
done
echo ""

echo "=== Teardown Complete ==="
echo ""
echo "Remaining manual cleanup (optional):"
echo "  - Delete appstacks in StackGen UI (they still exist as empty shells)"
echo "  - Delete the state backend: aws s3 rb s3://${BUCKET} --force"
echo "  - Delete the lock table: aws dynamodb delete-table --table-name cesar-demo-tfstate-lock"
echo "  - Delete the IAM role: aws iam delete-role-policy --role-name stackgen-retroboard-demo --policy-name retroboard-infra-permissions && aws iam delete-role --role-name stackgen-retroboard-demo"
echo ""
