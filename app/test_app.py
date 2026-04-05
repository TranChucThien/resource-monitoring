import pytest
from unittest.mock import patch
from app import app


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


def test_health_endpoint(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.get_json()["status"] == "healthy"


@patch("app.psutil.cpu_percent", return_value=50.0)
@patch("app.psutil.virtual_memory")
@patch("app.get_host_ip", return_value="192.168.1.1")
def test_index_normal(mock_ip, mock_mem, mock_cpu, client):
    mock_mem.return_value.percent = 40.0
    resp = client.get("/")
    assert resp.status_code == 200
    assert b"System Monitoring" in resp.data
    assert b"192.168.1.1" in resp.data
    assert b"scale up" not in resp.data


@patch("app.psutil.cpu_percent", return_value=90.0)
@patch("app.psutil.virtual_memory")
@patch("app.get_host_ip", return_value="10.0.0.1")
def test_index_high_usage_alert(mock_ip, mock_mem, mock_cpu, client):
    mock_mem.return_value.percent = 85.0
    resp = client.get("/")
    assert resp.status_code == 200
    assert b"scale up" in resp.data
