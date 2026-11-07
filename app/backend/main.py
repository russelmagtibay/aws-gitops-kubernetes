import os
import uuid
from datetime import datetime, timezone
from typing import List, Optional
import boto3
from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr

app = FastAPI(
    title="Lead Capture Microservice API",
    description="3-Tier Microservice Backend for Amazon EKS with DynamoDB & SNS integration",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

AWS_REGION = os.getenv("AWS_REGION", "ap-southeast-1")
DYNAMODB_TABLE = os.getenv("DYNAMODB_TABLE", "aws-gitops-eks-dev-leads")
SNS_TOPIC_ARN = os.getenv("SNS_TOPIC_ARN", "")

# Initialize AWS clients (EKS Pod Identity provides credentials dynamically)
dynamodb = boto3.resource("dynamodb", region_name=AWS_REGION)
sns_client = boto3.client("sns", region_name=AWS_REGION)


class LeadCreate(BaseModel):
    name: str
    email: EmailStr
    company: Optional[str] = ""
    notes: Optional[str] = ""


class Lead(BaseModel):
    id: str
    name: str
    email: str
    company: str
    notes: str
    created_at: str


@app.get("/health", status_code=status.HTTP_200_OK)
def health_check():
    """Liveness and Readiness probe endpoint."""
    return {
        "status": "healthy",
        "service": "lead-capture-backend",
        "region": AWS_REGION,
        "table": DYNAMODB_TABLE,
    }


@app.get("/api/leads", response_model=List[Lead], status_code=status.HTTP_200_OK)
def list_leads():
    """Retrieve all leads from DynamoDB."""
    try:
        table = dynamodb.Table(DYNAMODB_TABLE)
        response = table.scan()
        items = response.get("Items", [])
        return [
            Lead(
                id=item["id"],
                name=item.get("name", ""),
                email=item.get("email", ""),
                company=item.get("company", ""),
                notes=item.get("notes", ""),
                created_at=item.get("created_at", ""),
            )
            for item in items
        ]
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to scan leads: {str(e)}",
        )


@app.post("/api/leads", response_model=Lead, status_code=status.HTTP_201_CREATED)
def create_lead(lead: LeadCreate):
    """Save a new lead to DynamoDB and publish an alert to SNS."""
    lead_id = str(uuid.uuid4())
    timestamp = datetime.now(timezone.utc).isoformat()

    item = {
        "id": lead_id,
        "name": lead.name,
        "email": lead.email,
        "company": lead.company or "",
        "notes": lead.notes or "",
        "created_at": timestamp,
    }

    try:
        table = dynamodb.Table(DYNAMODB_TABLE)
        table.put_item(Item=item)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to persist lead in DynamoDB: {str(e)}",
        )

    # Publish notification to SNS topic if configured
    if SNS_TOPIC_ARN:
        try:
            sns_client.publish(
                TopicArn=SNS_TOPIC_ARN,
                Subject=f"New Lead Captured: {lead.name}",
                Message=(
                    f"New lead received!\n\n"
                    f"Name: {lead.name}\n"
                    f"Email: {lead.email}\n"
                    f"Company: {lead.company}\n"
                    f"Notes: {lead.notes}\n"
                    f"Timestamp: {timestamp}\n"
                    f"ID: {lead_id}\n"
                ),
            )
        except Exception as err:
            # Non-blocking log warning
            print(f"Warning: SNS publish failed: {err}")

    return Lead(**item)

