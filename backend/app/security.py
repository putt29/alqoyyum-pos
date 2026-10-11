"""Hashing password (bcrypt) & token JWT."""
import time
from typing import Optional

import bcrypt
import jwt

from . import config


def password_problem(plain: str) -> Optional[str]:
    if len(plain) < config.MIN_PASSWORD_LEN:
        return f"Password minimal {config.MIN_PASSWORD_LEN} karakter."
    if len(plain.encode("utf-8")) > config.MAX_PASSWORD_BYTES:
        return "Password terlalu panjang."
    return None


def hash_password(plain: str) -> str:
    return bcrypt.hashpw(plain.encode("utf-8"), bcrypt.gensalt(rounds=12)).decode("ascii")


def verify_password(plain: str, hashed: str) -> bool:
    try:
        if len(plain.encode("utf-8")) > config.MAX_PASSWORD_BYTES:
            return False
        return bcrypt.checkpw(plain.encode("utf-8"), hashed.encode("ascii"))
    except ValueError:
        return False


def create_token(secret: str, user_id: int, role: str, token_version: int) -> str:
    now = int(time.time())
    payload = {"sub": str(user_id), "role": role, "tv": token_version,
               "iat": now, "exp": now + config.TOKEN_TTL_MINUTES * 60}
    return jwt.encode(payload, secret, algorithm="HS256")


def decode_token(secret: str, token: str) -> Optional[dict]:
    try:
        return jwt.decode(token, secret, algorithms=["HS256"])
    except jwt.PyJWTError:
        return None
