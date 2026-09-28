# AGENTS.md

## Run locally
- `docker compose up --build -d` (no .env or AWS credentials needed).
- UI: http://localhost:3000, API: http://localhost:8000 (also via http://localhost:3000/api).
- AWS (DynamoDB, SQS, SNS, SES) is LocalStack. `localstack/init-aws.sh` creates the
  `boards` table, `retroboard-emails` queue and `retroboard-alerts` topic on every start.

## Shipyard
- Every branch push builds an environment from `docker-compose.yml`.
- Routes: `app` at `/`, `api` at `/api`. The frontend calls same-origin `/api`.
- Only named volumes are honored, so the init script is baked into `localstack/Dockerfile`.

Acceptance check: hit the environment URL with SHIPYARD_TOKEN sent as the `shipyard_token`
cookie. Never print the token.
