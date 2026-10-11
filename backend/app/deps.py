"""Dependency otorisasi - SEMUA pengecekan role dilakukan di server."""
import sqlite3

from fastapi import Depends, Header, HTTPException

from .db import get_db, jwt_secret
from .security import decode_token

UNAUTH = "Sesi tidak valid atau sudah berakhir. Silakan login kembali."


def current_user(authorization: str = Header(default=""),
                 conn: sqlite3.Connection = Depends(get_db)):
    if not authorization.lower().startswith("bearer "):
        raise HTTPException(401, UNAUTH)
    payload = decode_token(jwt_secret(conn), authorization[7:].strip())
    if not payload:
        raise HTTPException(401, UNAUTH)
    try:
        uid = int(payload.get("sub", "0"))
    except ValueError:
        raise HTTPException(401, UNAUTH)
    row = conn.execute("SELECT * FROM users WHERE id=?", (uid,)).fetchone()
    if row is None or not row["is_active"] or row["token_version"] != payload.get("tv"):
        raise HTTPException(401, UNAUTH)
    return row


def require_owner(user=Depends(current_user)):
    if user["role"] != "OWNER":
        raise HTTPException(403, "Hanya Owner yang dapat melakukan tindakan ini.")
    return user
