# retroboard

retroboard is a app written in **python** to create kanban boards that can be used for different purposes like capturing notes for a [Retrospective](https://www.atlassian.com/agile/scrum/retrospectives) meeting, creating a Pros/Cons list, tracking TODOs, etc.

This app demonstrates a containerized microservices application with multiple HTTP services that can be deployed to **AWS ECS**, uses **DynamoDB** for data storage and **SES** for sending summary emails. The UI of the app can be served with S3 or any static hosting service.

---

StackGen provides a powerful and flexible way to define and manage your infrastructure. We encourage you to use StackGen to generate IaC for this application and try and deploy this app in your own AWS Account.

Get started with IaC generation for this repo by following the instructions on [StackGen Documentation](https://docs.stackgen.com/get-started)


### Services

The application consists of three microservices:

1. **API Service** (`functions/api/`) - FastAPI REST API for managing boards and notes
2. **Email Summary Worker** (`functions/email-summary/`) - HTTP endpoint for processing SQS messages and sending email summaries via SES
3. **Slack Alerts Worker** (`functions/slack-alerts/`) - HTTP endpoint for processing SNS messages and sending alerts to Slack

All services are containerized and can be deployed to AWS ECS. Each service runs as a long-running HTTP server using Uvicorn.

### Environment Variables

#### API Service (`functions/api/`)
```
AWS_REGION - AWS region for DynamoDB, SNS, and SQS
CORS_ALLOWED_ORIGINS - Comma-separated list of allowed CORS origins
PORT - Port number for the HTTP server (default: 8000)
```

#### Email Summary Worker (`functions/email-summary/`)
```
SES_SENDER_EMAIL_ADDRESS - Email address from which the summary email will be sent
TEMPLATE_NAME - SES template name for email summaries (default: retroboard-summary)
PORT - Port number for the HTTP server (default: 8000)
```

#### Slack Alerts Worker (`functions/slack-alerts/`)
```
SLACK_WEBHOOK_URL - Slack webhook URL to send alerts when a new board is created
PORT - Port number for the HTTP server (default: 8000)
```

### Running Locally

#### Using Docker Compose (Recommended)

The easiest way to run all services locally is using Docker Compose. This will start all services including LocalStack for AWS service emulation:

```bash
# Start all services
docker-compose up

# Or run in detached mode
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down
```

This will start:
- **API Service** on `http://localhost:8000`
- **Email Summary Worker** on `http://localhost:8001`
- **Slack Alerts Worker** on `http://localhost:8002`
- **Frontend App** on `http://localhost:3000`
- **LocalStack** (AWS emulator) on `http://localhost:4566`

**Initializing LocalStack Resources**:

Before using the services, you need to initialize LocalStack resources (DynamoDB tables, SQS queues, SNS topics). After starting docker-compose, run:

```bash
# Make sure LocalStack is running, then initialize resources
./init-localstack.sh
```

Or manually initialize using AWS CLI:

```bash
# Create DynamoDB table
aws --endpoint-url=http://localhost:4566 dynamodb create-table \
  --table-name boards \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1

# Create SQS queue
aws --endpoint-url=http://localhost:4566 sqs create-queue \
  --queue-name retroboard-emails \
  --region us-east-1

# Create SNS topic
aws --endpoint-url=http://localhost:4566 sns create-topic \
  --name retroboard-alerts \
  --region us-east-1
```

**Note**: Make sure you have AWS CLI installed and configured (credentials can be dummy values for LocalStack).

**Customizing the API URL**:

The frontend app is configured to connect to `http://localhost:8000` by default. To change this, modify the `NEXT_PUBLIC_API_HOST_URL` build argument in `docker-compose.yml` and rebuild the app container:

```bash
docker-compose build app
docker-compose up
```

#### Using Python Directly

Each service can also be run locally using Python:

```bash
# API Service
cd functions/api
pip install -r requirements.txt
python main.py

# Email Summary Worker
cd functions/email-summary
pip install -r requirements.txt
python main.py

# Slack Alerts Worker
cd functions/slack-alerts
pip install -r requirements.txt
python main.py
```

#### Building Individual Docker Images

You can also build and run individual services using Docker:

```bash
# Build API service
docker build -t retroboard-api ./functions/api
docker run -p 8000:8000 \
  -e AWS_REGION=us-east-1 \
  -e CORS_ALLOWED_ORIGINS=http://localhost:3000 \
  retroboard-api

# Build Email Summary service
docker build -t retroboard-email-summary ./functions/email-summary
docker run -p 8001:8000 \
  -e SES_SENDER_EMAIL_ADDRESS=noreply@example.com \
  retroboard-email-summary

# Build Slack Alerts service
docker build -t retroboard-slack-alerts ./functions/slack-alerts
docker run -p 8002:8000 \
  -e SLACK_WEBHOOK_URL=http://localhost:3001/webhook \
  retroboard-slack-alerts

# Build Frontend app
docker build -t retroboard-app ./app
docker run -p 3000:3000 retroboard-app
```

### Testing

All services include comprehensive test suites using pytest. Run tests for each service:

```bash
# API Service tests
cd functions/api
pytest tests/ -v

# Email Summary Worker tests
cd functions/email-summary
pytest tests/ -v

# Slack Alerts Worker tests
cd functions/slack-alerts
pytest tests/ -v
```

Tests use mocked AWS services (via `moto`) and HTTP clients to verify functionality without requiring actual AWS credentials or external services.

### Architecture

![](arch.png)

The application uses:
- **FastAPI** for HTTP endpoints
- **DynamoDB** for data persistence
- **SNS** for event notifications (board creation alerts)
- **SQS** for email queue processing
- **SES** for sending email summaries
- **Slack Webhooks** for alert notifications

### Deployment

The services are designed to be deployed to AWS ECS:

1. **Container Images**: Each service includes a Dockerfile and can be built using the provided Dockerfiles:
   ```bash
   docker build -t retroboard-api ./functions/api
   docker build -t retroboard-email-summary ./functions/email-summary
   docker build -t retroboard-slack-alerts ./functions/slack-alerts
   docker build -t retroboard-app ./app
   ```
2. **ECS Tasks**: Deploy each service as a separate ECS task/service
3. **Load Balancer**: Use an Application Load Balancer (ALB) to route traffic to the API service
4. **SQS/SNS Integration**: Configure SQS queues and SNS topics to send HTTP POST requests to the worker services (via EventBridge, ALB, or direct HTTP endpoints)
5. **DynamoDB**: Ensure DynamoDB table exists and IAM roles have appropriate permissions

## Other Sample Projects to try

- [hello-kitty](https://github.com/StackGen-demo/hello-kitty) - a static website that can be deployed to Lambda and S3


## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
