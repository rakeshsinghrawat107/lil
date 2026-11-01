import pytest
from pathlib import Path
from backend.app.config import Config
from backend.app.db.migrate import main as run_migrations
from backend.app.db.seed import seed_database
from backend.app import create_app

@pytest.fixture(autouse=True, scope="session")
def setup_test_environment(tmp_path_factory):
    # Route all pytest tests to an isolated temporary SQLite database
    test_db = tmp_path_factory.mktemp("test_db") / "pytest_cultural_committee.db"
    Config.DATABASE_URL = f"sqlite:///{test_db}"
    run_migrations()
    seed_database()

@pytest.fixture
def app():
    app = create_app()
    app.config["TESTING"] = True
    return app

@pytest.fixture
def client(app):
    return app.test_client()

