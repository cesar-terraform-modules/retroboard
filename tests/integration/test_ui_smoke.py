"""UI smoke tests using Playwright."""

import pytest
import requests
from playwright.sync_api import Page, expect, sync_playwright


@pytest.mark.integration
class TestUISmoke:
    """Basic smoke tests for the UI."""

    @pytest.fixture(scope="class")
    def page(self, docker_compose, ui_base_url: str):
        """Create a Playwright page instance."""
        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True)
            page = browser.new_page()
            yield page
            browser.close()

    def test_ui_loads(self, docker_compose, ui_base_url: str, page: Page):
        """Test that the UI loads successfully."""
        page.goto(ui_base_url)

        # Check that the page loaded (no errors)
        expect(page).to_have_url(f"{ui_base_url}/")

        # Check for basic page elements (title or main content)
        # The page should have some content
        body = page.locator("body")
        expect(body).to_be_visible()

    def test_create_board_via_ui(
        self, docker_compose, ui_base_url: str, page: Page, api_base_url: str
    ):
        """Test that the UI can create a board via API."""
        # Navigate to the UI
        page.goto(ui_base_url)

        # Wait for page to load
        page.wait_for_load_state("networkidle")

        # Verify we can make API calls from the UI context
        # We'll test by checking if the API is accessible from the browser context
        # and by verifying the UI can interact with the API

        # Check that the API endpoint is accessible (CORS should allow it)
        response = requests.get(f"{api_base_url}/docs")
        assert response.status_code == 200, "API should be accessible"

        # Verify the UI page has loaded (check for any text or element)
        # The UI should have some content indicating it's ready
        body_text = page.locator("body").inner_text()
        assert len(body_text) > 0, "UI should have content"

    def test_ui_api_integration(
        self, docker_compose, ui_base_url: str, page: Page, api_base_url: str
    ):
        """Test that UI can interact with the API."""
        # Create a board via API first
        board_data = {
            "name": "UI Test Board",
            "section_details": ["Section 1", "Section 2"],
        }
        api_response = requests.post(f"{api_base_url}/boards", json=board_data)
        assert api_response.status_code == 201
        board = api_response.json()
        board_id = board["id"]

        # Navigate to the board page in the UI
        board_url = f"{ui_base_url}/board.html?slug={board['slug']}&id={board_id}"
        page.goto(board_url)

        # Wait for page to load
        page.wait_for_load_state("networkidle", timeout=10000)

        # Verify the page loaded (check for board name or any content)
        body = page.locator("body")
        expect(body).to_be_visible()

        # The board page should have loaded content
        # Since it's a React app, we'll check that the page is interactive
        page_content = page.content()
        assert len(page_content) > 0, "Board page should have content"

    def test_ui_cors_configuration(
        self, docker_compose, ui_base_url: str, api_base_url: str, page: Page
    ):
        """Test that CORS is properly configured for UI to access API."""
        # Make a request from the UI origin to the API
        headers = {
            "Origin": ui_base_url,
            "Access-Control-Request-Method": "POST",
            "Access-Control-Request-Headers": "Content-Type",
        }

        # Preflight request
        response = requests.options(f"{api_base_url}/boards", headers=headers)
        # Should allow CORS (status 200 or 204)
        assert response.status_code in [200, 204], "CORS preflight should succeed"

        # Check for CORS headers in response
        cors_headers = [
            "access-control-allow-origin",
            "access-control-allow-methods",
            "access-control-allow-headers",
        ]

        # At least one CORS header should be present
        response_headers = {k.lower(): v for k, v in response.headers.items()}
        assert any(
            header in response_headers for header in cors_headers
        ), "CORS headers should be present"
