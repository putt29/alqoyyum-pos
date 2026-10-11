"""Login, sesi, dan manajemen akun kasir (Owner)."""
import sqlite3
import time

from fastapi import APIRouter, Depends, HTTPException, Request

from . import config
from .db import audit, get_db, jwt_secret, now_iso
from .deps import current_user, require_owner
from .schemas import ChangePasswordIn, LoginIn, UserCreate, UserPatch
from .security import create_token, hash_password, password_problem, verify_password

router = APIRouter(prefix="/api")

_FAILS = {}            # key -> [timestamps]; pembatas percobaan login sederhana
_WINDOW, _MAX_FAILS = 300, 10


def _blocked(key: str) -> bool:
    now = time.time()
    hits = [t for t in _FAILS.get(key, []) if now - t < _WINDOW]
    _FAILS[key] = hits
    return len(hits) >= _MAX_FAILS


def user_out(r) -> dict:
    return {"id": r["id"], "username": r["username"], "full_name": r["full_name"],
            "role": r["role"], "is_active": bool(r["is_active"]),
            "created_at": r["created_at"]}


@router.post("/auth/login")
def login(body: LoginIn, request: Request, conn: sqlite3.Connection = Depends(get_db)):
    username = body.username.strip()
    ip = request.client.host if request.client else "?"
    key = f"{ip}|{username.lower()}"
    if _blocked(key):
        raise HTTPException(429, "Terlalu banyak percobaan login. Coba lagi beberapa menit lagi.")
    row = conn.execute("SELECT * FROM users WHERE username=?", (username,)).fetchone()
    if row is None or not row["is_active"] or not verify_password(body.password, row["password_hash"]):
        _FAILS.setdefault(key, []).append(time.time())
        audit(conn, {"id": row["id"] if row else None, "username": username}, "LOGIN_FAILED",
              "user", row["id"] if row else None, f"Login gagal untuk '{username}'")
        raise HTTPException(401, "Username atau password salah.")
    _FAILS.pop(key, None)
    token = create_token(jwt_secret(conn), row["id"], row["role"], row["token_version"])
    audit(conn, row, "LOGIN", "user", row["id"], f"{row['full_name']} ({row['role']}) login")
    return {"access_token": token, "token_type": "bearer",
            "expires_in": config.TOKEN_TTL_MINUTES * 60, "user": user_out(row)}


@router.get("/auth/me")
def me(user=Depends(current_user)):
    return user_out(user)


@router.post("/auth/logout")
def logout(user=Depends(current_user), conn: sqlite3.Connection = Depends(get_db)):
    audit(conn, user, "LOGOUT", "user", user["id"], f"{user['full_name']} logout")
    return {"ok": True}


@router.post("/auth/change-password")
def change_password(body: ChangePasswordIn, user=Depends(current_user),
                    conn: sqlite3.Connection = Depends(get_db)):
    if not verify_password(body.old_password, user["password_hash"]):
        raise HTTPException(400, "Password lama salah.")
    problem = password_problem(body.new_password)
    if problem:
        raise HTTPException(400, problem)
    conn.execute("UPDATE users SET password_hash=?, token_version=token_version+1, updated_at=? WHERE id=?",
                 (hash_password(body.new_password), now_iso(), user["id"]))
    audit(conn, user, "CHANGE_PASSWORD", "user", user["id"], f"{user['full_name']} mengganti password")
    row = conn.execute("SELECT * FROM users WHERE id=?", (user["id"],)).fetchone()
    token = create_token(jwt_secret(conn), row["id"], row["role"], row["token_version"])
    return {"ok": True, "access_token": token}


# ---------------- Manajemen akun (OWNER) ----------------
@router.get("/users")
def list_users(owner=Depends(require_owner), conn: sqlite3.Connection = Depends(get_db)):
    rows = conn.execute("SELECT * FROM users ORDER BY role DESC, full_name COLLATE NOCASE").fetchall()
    return [user_out(r) for r in rows]


@router.post("/users", status_code=201)
def create_user(body: UserCreate, owner=Depends(require_owner),
                conn: sqlite3.Connection = Depends(get_db)):
    problem = password_problem(body.password)
    if problem:
        raise HTTPException(400, problem)
    if conn.execute("SELECT 1 FROM users WHERE username=?", (body.username,)).fetchone():
        raise HTTPException(409, "Username sudah dipakai.")
    ts = now_iso()
    cur = conn.execute(
        "INSERT INTO users(username,full_name,password_hash,role,is_active,created_at,updated_at)"
        " VALUES(?,?,?,?,1,?,?)",
        (body.username, body.full_name.strip(), hash_password(body.password), "KASIR", ts, ts))
    audit(conn, owner, "CREATE_USER", "user", cur.lastrowid,
          f"Akun kasir '{body.username}' ({body.full_name.strip()}) dibuat")
    return user_out(conn.execute("SELECT * FROM users WHERE id=?", (cur.lastrowid,)).fetchone())


@router.patch("/users/{user_id}")
def update_user(user_id: int, body: UserPatch, owner=Depends(require_owner),
                conn: sqlite3.Connection = Depends(get_db)):
    row = conn.execute("SELECT * FROM users WHERE id=?", (user_id,)).fetchone()
    if row is None:
        raise HTTPException(404, "Akun tidak ditemukan.")
    if row["role"] != "KASIR":
        raise HTTPException(403, "Akun Owner tidak dapat diubah dari sini.")
    sets, vals, notes = [], [], []
    if body.full_name is not None:
        sets.append("full_name=?"); vals.append(body.full_name.strip()); notes.append("nama")
    if body.password:
        problem = password_problem(body.password)
        if problem:
            raise HTTPException(400, problem)
        sets += ["password_hash=?", "token_version=token_version+1"]
        vals.append(hash_password(body.password)); notes.append("password direset")
    if body.is_active is not None and bool(row["is_active"]) != body.is_active:
        sets.append("is_active=?"); vals.append(1 if body.is_active else 0)
        sets.append("token_version=token_version+1")
        notes.append("diaktifkan" if body.is_active else "dinonaktifkan")
    if sets:
        sets.append("updated_at=?"); vals.append(now_iso())
        conn.execute(f"UPDATE users SET {', '.join(sets)} WHERE id=?", (*vals, user_id))
        audit(conn, owner, "UPDATE_USER", "user", user_id,
              f"Akun kasir '{row['username']}': " + ", ".join(notes))
    return user_out(conn.execute("SELECT * FROM users WHERE id=?", (user_id,)).fetchone())
