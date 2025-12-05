import os
import urllib3
import json
from fastapi import FastAPI, Request, HTTPException, status
from pydantic import BaseModel
from typing import List, Dict, Any

WEBHOOK_URL = os.environ["SLACK_WEBHOOK_URL"]

app = FastAPI()
http = urllib3.PoolManager()


class SNSRecord(BaseModel):
    Sns: Dict[str, Any]


class SNSMessage(BaseModel):
    Records: List[SNSRecord]


@app.post("/")
@app.post("/process")
async def process_slack_alert(request: Request):
    """Process SNS messages for Slack alerts"""
    try:
        # Parse request body
        body = await request.json()

        # Handle different SNS message formats
        if "Records" in body and len(body["Records"]) > 0:
            # Lambda event format (for compatibility)
            message = body["Records"][0]["Sns"]["Message"]
        elif "Message" in body:
            # Direct SNS HTTP notification format
            message = body["Message"]
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid message format. Expected 'Records' or 'Message' field.",
            )

        msg = {"text": message}

        encoded_msg = json.dumps(msg).encode("utf-8")
        resp = http.request("POST", WEBHOOK_URL, body=encoded_msg)

        result = {
            "message": message,
            "status_code": resp.status,
            "response": resp.data.decode("utf-8") if resp.data else None,
        }
        print(result)

        if resp.status >= 400:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"Slack webhook returned error: {resp.status}",
            )

        return {"status": "success", "slack_status": resp.status}
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error processing Slack alert: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error processing Slack alert: {str(e)}",
        )


if __name__ == "__main__":
    import uvicorn

    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
