from unittest.mock import MagicMock, patch
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)


def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["service"] == "lead-capture-backend"


@patch("main.dynamodb.Table")
def test_create_lead_success(mock_table):
    mock_table_instance = MagicMock()
    mock_table.return_value = mock_table_instance
    mock_table_instance.put_item.return_value = {}

    payload = {
        "name": "Jane Doe",
        "email": "jane@example.com",
        "company": "Acme Corp",
        "notes": "Interested in EKS GitOps platform",
    }

    response = client.post("/api/leads", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Jane Doe"
    assert data["email"] == "jane@example.com"
    assert data["company"] == "Acme Corp"
    assert "id" in data
    assert "created_at" in data
    mock_table_instance.put_item.assert_called_once()


@patch("main.dynamodb.Table")
def test_list_leads_success(mock_table):
    mock_table_instance = MagicMock()
    mock_table.return_value = mock_table_instance
    mock_table_instance.scan.return_value = {
        "Items": [
            {
                "id": "123",
                "name": "Jane Doe",
                "email": "jane@example.com",
                "company": "Acme Corp",
                "notes": "Interested",
                "created_at": "2026-11-07T00:00:00Z",
            }
        ]
    }

    response = client.get("/api/leads")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["id"] == "123"
    assert data[0]["name"] == "Jane Doe"

