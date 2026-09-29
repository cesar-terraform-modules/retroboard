# AGENTS.md

## Run locally
- `docker compose up --build -d` (no .env or AWS credentials needed).
- UI: http://localhost:3000, API: http://localhost:8000 (also via http://localhost:3000/api).
- AWS (DynamoDB, SQS, SNS, SES) is LocalStack, initialized on every start by
  `localstack/init-aws.sh`.

Acceptance check: hit the environment URL with SHIPYARD_TOKEN sent as the `shipyard_token`
cookie. Never print the token.
