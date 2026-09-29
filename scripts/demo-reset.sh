#!/usr/bin/env bash
# Reset between demo takes: delete local and remote fix/* branches not merged into
# origin/main (merged ones are history), then confirm main's Shipyard environment is
# still ready on origin/main's commit.
# Read-only for main and its environment. Usage: scripts/demo-reset.sh [expected-main-sha]
set -euo pipefail

REPO_NAME=retroboard
fail() { echo "FAIL: $*"; exit 1; }

git fetch --quiet --prune origin
expected=${1:-$(git rev-parse origin/main)}

current=$(git branch --show-current)
[[ $current == fix/* ]] && fail "currently on $current; switch branches first"

for b in $(git for-each-ref --no-merged=origin/main --format='%(refname:short)' 'refs/heads/fix/*'); do
  git branch -D "$b" >/dev/null && echo "deleted local $b"
done
for b in $(git for-each-ref --no-merged=origin/main --format='%(refname:lstrip=3)' 'refs/remotes/origin/fix/*'); do
  git push --quiet origin --delete "$b" && echo "deleted remote $b"
done

state=$(shipyard get environments --repo-name "$REPO_NAME" --branch main --json |
  python3 -c '
import json, sys
for env in json.load(sys.stdin).get("data", []):
    a = env["attributes"]
    for p in a["projects"]:
        if p["repo_name"] == "'"$REPO_NAME"'" and p["branch"] == "main" and not p["pull_request_number"]:
            print(p["commit_hash"] or "-", a["ready"], a["processing"], a["stopped"])
            sys.exit()
print("missing")')

[[ $state == missing ]] && fail "no Shipyard environment found for main"
read -r sha ready processing stopped <<<"$state"
[[ $sha == "$expected" ]] || fail "main env serves ${sha:0:7}, expected ${expected:0:7}"
[[ $ready == True && $processing == False && $stopped == False ]] ||
  fail "main env not ready (ready=$ready processing=$processing stopped=$stopped)"

echo "PASS: no unmerged fix/* branches; main env ready on ${sha:0:7}"
