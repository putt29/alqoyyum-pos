import os
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))
_TMP = tempfile.mkdtemp(prefix="alq-test-")
os.environ["DB_PATH"] = str(Path(_TMP) / "test.db")
os.environ["JWT_SECRET"] = "test-secret-not-for-production"

import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402

from app import seed  # noqa: E402
from app.db import connect, init_db  # noqa: E402
from app.main import app  # noqa: E402


@pytest.fixture(scope="session")
def client():
    init_db()
    conn = connect()
    seed.seed_catalog(conn)
    seed.ensure_user(conn, "owner", "Owner", "owner-pass-1", "OWNER")
    seed.ensure_user(conn, "nunung", "Nunung Nurjanah", "kasir-pass-1", "KASIR")
    seed.ensure_user(conn, "kasir2", "Kasir Dua", "kasir-pass-2", "KASIR")
    conn.close()
    with TestClient(app) as c:
        yield c


def _login(client, user, pw):
    r = client.post("/api/auth/login", json={"username": user, "password": pw})
    assert r.status_code == 200, r.text
    return {"Authorization": "Bearer " + r.json()["access_token"]}


@pytest.fixture(scope="session")
def owner_h(client):
    return _login(client, "owner", "owner-pass-1")


@pytest.fixture(scope="session")
def kasir_h(client):
    return _login(client, "nunung", "kasir-pass-1")


@pytest.fixture(scope="session")
def kasir2_h(client):
    return _login(client, "kasir2", "kasir-pass-2")


@pytest.fixture(scope="session")
def pid(client, owner_h):
    """Cari id produk berdasarkan nama (case-insensitive)."""
    rows = client.get("/api/products?include_inactive=true", headers=owner_h).json()
    index = {}
    for p in rows:
        index.setdefault(p["name"].lower(), p["id"])

    def find(name):
        return index[name.lower()]
    return find
