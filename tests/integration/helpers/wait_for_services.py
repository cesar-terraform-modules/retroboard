"""Helper functions to wait for services to be ready."""

import time
import requests
from typing import Optional


def wait_for_service(
    url: str,
    timeout: int = 60,
    interval: int = 2,
    expected_status: int = 200,
) -> bool:
    """
    Wait for a service to be ready by checking its health endpoint.

    Args:
        url: The URL to check
        timeout: Maximum time to wait in seconds
        interval: Time between checks in seconds
        expected_status: Expected HTTP status code

    Returns:
        True if service is ready, False if timeout exceeded
    """
    start_time = time.time()
    while time.time() - start_time < timeout:
        try:
            response = requests.get(url, timeout=5)
            if response.status_code == expected_status:
                return True
        except requests.exceptions.RequestException:
            pass
        time.sleep(interval)
    return False


def wait_for_api(base_url: str = "http://localhost:8000", timeout: int = 60) -> bool:
    """Wait for the API service to be ready."""
    return wait_for_service(f"{base_url}/docs", timeout=timeout)


def wait_for_ui(base_url: str = "http://localhost:3000", timeout: int = 60) -> bool:
    """Wait for the UI service to be ready."""
    return wait_for_service(base_url, timeout=timeout)


def wait_for_localstack(
    base_url: str = "http://localhost:4566", timeout: int = 60
) -> bool:
    """Wait for LocalStack to be ready."""
    return wait_for_service(f"{base_url}/_localstack/health", timeout=timeout)
