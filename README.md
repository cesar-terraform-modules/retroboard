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

Each service can be run locally using Python:

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

1. **Container Images**: Each service should be containerized (Dockerfile not included, but standard Python/FastAPI Docker images work)
2. **ECS Tasks**: Deploy each service as a separate ECS task/service
3. **Load Balancer**: Use an Application Load Balancer (ALB) to route traffic to the API service
4. **SQS/SNS Integration**: Configure SQS queues and SNS topics to send HTTP POST requests to the worker services (via EventBridge, ALB, or direct HTTP endpoints)
5. **DynamoDB**: Ensure DynamoDB table exists and IAM roles have appropriate permissions

## Other Sample Projects to try

- [hello-kitty](https://github.com/StackGen-demo/hello-kitty) - a static website that can be deployed to Lambda and S3


## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
