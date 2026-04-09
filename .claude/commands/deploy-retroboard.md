I have a web app called "retroboard" that I need to deploy to AWS using StackGen.
My project is "cesar-retroboard-demo" on stage.dev.stackgen.com.

Our platform team already provisioned networking in "cesar-demo-core-infra" and
ECR repos in a "retroboard-registry" appstack. Container images are pre-built and
pushed to 180217099948.dkr.ecr.us-east-1.amazonaws.com/retroboard/{api,app,email-summary,notification-service}:latest.

I need a single appstack called "retroboard" with everything my app needs:

**4 ECS Fargate services** on a cluster called "retroboard-dev":
- api (port 8000) -- FastAPI, needs DynamoDB, SQS, SNS. ALB path routes: /boards*, /email-summary*, /docs*
- app (port 3000) -- Next.js/nginx frontend. ALB default route.
- email-summary (port 8000) -- internal, service discovery, needs SES + SQS
- notification (port 8000) -- internal, service discovery, needs Slack webhook

**Supporting resources**: DynamoDB table (board_id/sk keys), SQS queue + DLQ,
SNS topic, SES email (noreply@example.com, already verified), ALB with blue-green
target groups for api and app, service discovery namespace, and IAM roles for each
service group.

All resource names follow the pattern: retroboard-dev-{resource}.
State backend: s3://cesar-demo-tfstate-180217099948/retroboard/retroboard.tfstate
with DynamoDB lock table cesar-demo-tfstate-lock.

Create the appstack, configure everything, and apply it.
