import json
import os
import boto3
from fastapi import FastAPI, HTTPException, status
from pydantic import BaseModel
from typing import List, Dict, Any
from botocore.errorfactory import ClientError

SENDER_EMAIL = os.environ["SES_SENDER_EMAIL_ADDRESS"]
TEMPLATE_NAME = "retroboard-summary"

app = FastAPI()

ses_client = boto3.client("ses")


class SQSRecord(BaseModel):
    body: str
    messageId: str = None
    receiptHandle: str = None
    attributes: Dict[str, Any] = None
    messageAttributes: Dict[str, Any] = None


class SQSMessage(BaseModel):
    Records: List[SQSRecord]


@app.post("/")
@app.post("/process")
def process_email(event: SQSMessage):
    """Process SQS messages for email sending"""
    try:
        for record in event.Records:
            print(record.body)
            payload = json.loads(record.body)
            print("type(payload)", type(payload))

            send_args = {
                "Source": SENDER_EMAIL,
                "Template": TEMPLATE_NAME,
                "Destination": {"ToAddresses": [payload["to"]]},
                "TemplateData": record.body,
            }

            try:
                ses_response = ses_client.send_templated_email(**send_args)
                message_id = ses_response["MessageId"]
                print(f"Email sent to {payload['to']} with message id {message_id}")
            except ClientError as e:
                print(e.response["Error"]["Message"])
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail=f"Failed to send email: {e.response['Error']['Message']}",
                )

        return {"status": "success", "processed": len(event.Records)}
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error processing email: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error processing email: {str(e)}",
        )


if __name__ == "__main__":
    import uvicorn

    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
