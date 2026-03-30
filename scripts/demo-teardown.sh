#!/usr/bin/env bash
set -euo pipefail

# StackGen Demo Teardown Script
# Destroys all demo infrastructure to avoid ongoing AWS costs.
# Uses Claude CLI with StackGen MCP to destroy appstacks in reverse dependency order.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "=== StackGen Demo Teardown ==="
echo "Account: ${ACCOUNT_ID}"
echo "Region:  ${REGION}"
echo ""
echo "This will DESTROY all retroboard demo infrastructure."
echo "Press Ctrl+C to cancel, or Enter to continue..."
read -r

# --- 1. Destroy compute (depends on everything else) ---
echo "[1/5] Destroying retroboard-compute..."
claude --print -p "
Using the StackGen user MCP, find the retroboard-compute appstack in the
cesar-retroboard-demo project (project_id: 32f41853-b8b2-4cf8-ba03-61604521e10c).
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
Using the StackGen user MCP, find these appstacks in the cesar-retroboard-demo
project (project_id: 32f41853-b8b2-4cf8-ba03-61604521e10c):
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
