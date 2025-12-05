"""Pytest configuration and fixtures for integration tests."""

import os
import pytest
import subprocess
import time
from pathlib import Path
from typing import Generator

from helpers.wait_for_services import wait_for_api, wait_for_ui, wait_for_localstack
from helpers.localstack_init import initialize_localstack_resources


# Get the project root directory
PROJECT_ROOT = Path(__file__).parent.parent.parent
DOCKER_COMPOSE_FILE = PROJECT_ROOT / "docker-compose.yml"


@pytest.fixture(scope="session")
def docker_compose():
    """Start docker-compose services and clean up after tests."""
    # Start services
    print("Starting docker-compose services...")
    subprocess.run(
        ["docker-compose", "-f", str(DOCKER_COMPOSE_FILE), "up", "-d"],
        cwd=PROJECT_ROOT,
        check=True,
    )

    # Wait for services to be ready
    print("Waiting for LocalStack to be ready...")
    assert wait_for_localstack(timeout=120), "LocalStack failed to start"

    print("Waiting for API to be ready...")
    assert wait_for_api(timeout=120), "API failed to start"

    print("Waiting for UI to be ready...")
    assert wait_for_ui(timeout=120), "UI failed to start"

    # Initialize LocalStack resources
    print("Initializing LocalStack resources...")
    initialize_localstack_resources()

    # Give services a moment to fully initialize
    time.sleep(5)

    yield

    # Cleanup: stop services
    print("Stopping docker-compose services...")
    subprocess.run(
        ["docker-compose", "-f", str(DOCKER_COMPOSE_FILE), "down", "-v"],
        cwd=PROJECT_ROOT,
        check=False,  # Don't fail if cleanup fails
    )


@pytest.fixture(scope="session")
def api_base_url() -> str:
    """Base URL for the API service."""
    return os.getenv("API_BASE_URL", "http://localhost:8000")


@pytest.fixture(scope="session")
def ui_base_url() -> str:
    """Base URL for the UI service."""
    return os.getenv("UI_BASE_URL", "http://localhost:3000")


@pytest.fixture(scope="session")
def localstack_endpoint() -> str:
    """LocalStack endpoint URL."""
    return os.getenv("LOCALSTACK_ENDPOINT", "http://localhost:4566")
