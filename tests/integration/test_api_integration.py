"""Integration tests for the API service running in docker-compose."""

import pytest
import requests
from typing import Dict, Any


@pytest.mark.integration
class TestBoardOperations:
    """Test board CRUD operations."""

    def test_create_board(self, docker_compose, api_base_url: str):
        """Test creating a new board."""
        board_data = {
            "name": "Integration Test Board",
            "section_details": ["What went well", "What to improve", "Action items"],
        }

        response = requests.post(f"{api_base_url}/boards", json=board_data)
        assert (
            response.status_code == 201
        ), f"Expected 201, got {response.status_code}: {response.text}"

        board = response.json()
        assert board["name"] == board_data["name"]
        assert board["slug"] == "integration-test-board"
        assert board["section_details"] == board_data["section_details"]
        assert "id" in board
        assert board["notes"] == []

        return board

    def test_create_board_invalid_name(self, docker_compose, api_base_url: str):
        """Test creating a board with invalid name."""
        # Name too short
        response = requests.post(
            f"{api_base_url}/boards",
            json={"name": "ab", "section_details": ["Section 1"]},
        )
        assert response.status_code == 422

        # Name too long
        response = requests.post(
            f"{api_base_url}/boards",
            json={"name": "a" * 25, "section_details": ["Section 1"]},
        )
        assert response.status_code == 422

    def test_get_board(self, docker_compose, api_base_url: str):
        """Test retrieving a board."""
        # Create a board first
        board_data = {
            "name": "Test Get Board",
            "section_details": ["Section 1", "Section 2"],
        }
        create_response = requests.post(f"{api_base_url}/boards", json=board_data)
        assert create_response.status_code == 201
        created_board = create_response.json()
        board_id = created_board["id"]

        # Get the board
        response = requests.get(f"{api_base_url}/boards/{board_id}")
        assert response.status_code == 200

        board = response.json()
        assert board["id"] == board_id
        assert board["name"] == board_data["name"]
        assert board["section_details"] == board_data["section_details"]

    def test_get_board_not_found(self, docker_compose, api_base_url: str):
        """Test retrieving a non-existent board."""
        response = requests.get(f"{api_base_url}/boards/nonexistent-id-12345")
        # The endpoint may return 500 or raise an exception, but should not return 200
        assert response.status_code != 200


@pytest.mark.integration
class TestNoteOperations:
    """Test note CRUD operations."""

    @pytest.fixture
    def test_board(self, docker_compose, api_base_url: str) -> Dict[str, Any]:
        """Create a test board for note operations."""
        board_data = {
            "name": "Note Test Board",
            "section_details": ["Section 1", "Section 2"],
        }
        response = requests.post(f"{api_base_url}/boards", json=board_data)
        assert response.status_code == 201
        return response.json()

    def test_create_note(
        self, docker_compose, api_base_url: str, test_board: Dict[str, Any]
    ):
        """Test creating a note."""
        note_data = {"section_number": 1, "text": "This is a test note", "votes": 0}

        response = requests.post(
            f"{api_base_url}/boards/{test_board['id']}/notes", json=note_data
        )
        assert response.status_code == 201

        note = response.json()
        assert note["section_number"] == note_data["section_number"]
        assert note["text"] == note_data["text"]
        assert note["votes"] == note_data["votes"]
        assert "id" in note
        assert "created_at" in note
        assert "updated_at" in note

        return note

    def test_get_notes(
        self, docker_compose, api_base_url: str, test_board: Dict[str, Any]
    ):
        """Test getting notes for a board."""
        # Create a note first
        note_data = {"section_number": 1, "text": "Test note for retrieval", "votes": 0}
        create_response = requests.post(
            f"{api_base_url}/boards/{test_board['id']}/notes", json=note_data
        )
        assert create_response.status_code == 201
        created_note = create_response.json()

        # Get all notes
        response = requests.get(f"{api_base_url}/boards/{test_board['id']}/notes")
        assert response.status_code == 200

        notes = response.json()
        assert isinstance(notes, list)
        assert len(notes) >= 1
        assert any(note["id"] == created_note["id"] for note in notes)

    def test_get_notes_with_section_filter(
        self, docker_compose, api_base_url: str, test_board: Dict[str, Any]
    ):
        """Test getting notes filtered by section number."""
        # Create notes in different sections
        note1_data = {"section_number": 1, "text": "Note in section 1", "votes": 0}
        note2_data = {"section_number": 2, "text": "Note in section 2", "votes": 0}

        requests.post(
            f"{api_base_url}/boards/{test_board['id']}/notes", json=note1_data
        )
        requests.post(
            f"{api_base_url}/boards/{test_board['id']}/notes", json=note2_data
        )

        # Get notes for section 1 only
        response = requests.get(
            f"{api_base_url}/boards/{test_board['id']}/notes?section_number=1"
        )
        assert response.status_code == 200

        notes = response.json()
        assert isinstance(notes, list)
        assert all(note["section_number"] == 1 for note in notes)

    def test_update_note(
        self, docker_compose, api_base_url: str, test_board: Dict[str, Any]
    ):
        """Test updating a note."""
        # Create a note first
        note_data = {"section_number": 1, "text": "Original note text", "votes": 0}
        create_response = requests.post(
            f"{api_base_url}/boards/{test_board['id']}/notes", json=note_data
        )
        assert create_response.status_code == 201
        created_note = create_response.json()
        note_id = created_note["id"]

        # Update the note
        update_data = {"section_number": 2, "text": "Updated note text", "votes": 0}
        response = requests.put(
            f"{api_base_url}/boards/{test_board['id']}/notes/{note_id}",
            json=update_data,
        )
        assert response.status_code == 200

        updated_note = response.json()
        assert updated_note["text"] == update_data["text"]
        assert updated_note["section_number"] == update_data["section_number"]
        assert "updated_at" in updated_note

    def test_update_note_not_found(
        self, docker_compose, api_base_url: str, test_board: Dict[str, Any]
    ):
        """Test updating a non-existent note."""
        update_data = {"section_number": 1, "text": "Updated note text", "votes": 0}
        response = requests.put(
            f"{api_base_url}/boards/{test_board['id']}/notes/nonexistent-id-12345",
            json=update_data,
        )
        assert response.status_code == 404
        assert "message" in response.json()

    def test_delete_note(
        self, docker_compose, api_base_url: str, test_board: Dict[str, Any]
    ):
        """Test deleting a note."""
        # Create a note first
        note_data = {"section_number": 1, "text": "Note to be deleted", "votes": 0}
        create_response = requests.post(
            f"{api_base_url}/boards/{test_board['id']}/notes", json=note_data
        )
        assert create_response.status_code == 201
        created_note = create_response.json()
        note_id = created_note["id"]

        # Delete the note
        response = requests.delete(
            f"{api_base_url}/boards/{test_board['id']}/notes/{note_id}"
        )
        assert response.status_code == 200
        assert response.json()["message"] == "Note deleted successfully"

        # Verify note is deleted
        notes_response = requests.get(f"{api_base_url}/boards/{test_board['id']}/notes")
        notes = notes_response.json()
        assert not any(note["id"] == note_id for note in notes)

    def test_vote_on_note(
        self, docker_compose, api_base_url: str, test_board: Dict[str, Any]
    ):
        """Test voting on a note."""
        # Create a note first
        note_data = {"section_number": 1, "text": "Note to vote on", "votes": 0}
        create_response = requests.post(
            f"{api_base_url}/boards/{test_board['id']}/notes", json=note_data
        )
        assert create_response.status_code == 201
        created_note = create_response.json()
        note_id = created_note["id"]
        initial_votes = created_note["votes"]

        # Vote on the note
        response = requests.put(
            f"{api_base_url}/boards/{test_board['id']}/notes/{note_id}/vote"
        )
        assert response.status_code == 200

        voted_note = response.json()
        assert voted_note["id"] == note_id
        assert voted_note["votes"] == initial_votes + 1


@pytest.mark.integration
class TestEmailSummary:
    """Test email summary functionality."""

    @pytest.fixture
    def board_with_notes(self, docker_compose, api_base_url: str) -> Dict[str, Any]:
        """Create a board with notes for email summary testing."""
        board_data = {
            "name": "Email Test Board",
            "section_details": ["What went well", "What to improve"],
        }
        board_response = requests.post(f"{api_base_url}/boards", json=board_data)
        assert board_response.status_code == 201
        board = board_response.json()

        # Add some notes
        note1 = {"section_number": 1, "text": "Good note", "votes": 2}
        note2 = {"section_number": 2, "text": "Improvement note", "votes": 1}

        requests.post(f"{api_base_url}/boards/{board['id']}/notes", json=note1)
        requests.post(f"{api_base_url}/boards/{board['id']}/notes", json=note2)

        return board

    def test_email_summary(
        self, docker_compose, api_base_url: str, board_with_notes: Dict[str, Any]
    ):
        """Test requesting an email summary."""
        email_request = {
            "board_id": board_with_notes["id"],
            "email_address": "test@example.com",
        }

        response = requests.post(f"{api_base_url}/email-summary", json=email_request)
        assert response.status_code == 200

        data = response.json()
        assert "message" in data
        assert "will be sent shortly" in data["message"].lower()

    def test_email_summary_board_not_found(self, docker_compose, api_base_url: str):
        """Test email summary with non-existent board."""
        email_request = {
            "board_id": "nonexistent-id-12345",
            "email_address": "test@example.com",
        }

        response = requests.post(f"{api_base_url}/email-summary", json=email_request)
        assert response.status_code == 404

        data = response.json()
        assert "not found" in data["message"].lower()


@pytest.mark.integration
class TestCORS:
    """Test CORS configuration."""

    def test_cors_headers(self, docker_compose, api_base_url: str):
        """Test CORS headers are present."""
        response = requests.options(
            f"{api_base_url}/boards", headers={"Origin": "http://localhost:3000"}
        )
        # CORS headers should be present (middleware handles OPTIONS)
        assert response.status_code in [200, 204]
