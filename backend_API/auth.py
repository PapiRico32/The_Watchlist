import base64
import hashlib
import hmac
import json
import os

from fastapi import Depends, HTTPException, Header
from sqlalchemy.orm import Session

from database import get_db
from models import Usuario

SECRET_KEY = os.getenv("SECRET_KEY", "the-watchlist-dev-secret")


def hash_password(password: str) -> str:
    salt = os.urandom(16).hex()
    digest = hashlib.pbkdf2_hmac(
        "sha256", password.encode("utf-8"), salt.encode("utf-8"), 100000
    ).hex()
    return f"pbkdf2${salt}${digest}"


def verificar_password(password: str, stored: str) -> bool:
    try:
        _, salt, digest = stored.split("$", 2)
    except ValueError:
        return False

    calculado = hashlib.pbkdf2_hmac(
        "sha256", password.encode("utf-8"), salt.encode("utf-8"), 100000
    ).hex()
    return hmac.compare_digest(calculado, digest)


def crear_token(data: dict) -> str:
    payload = base64.urlsafe_b64encode(
        json.dumps(data).encode("utf-8")
    ).decode("utf-8").rstrip("=")
    firma = hmac.new(
        SECRET_KEY.encode("utf-8"), payload.encode("utf-8"), hashlib.sha256
    ).hexdigest()
    return f"{payload}.{firma}"


def get_current_user(
    authorization: str = Header(default=None),
    db: Session = Depends(get_db),
) -> Usuario:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="No autenticado")

    token = authorization.split(" ", 1)[1].strip()

    try:
        payload, firma = token.split(".", 1)
        firma_esperada = hmac.new(
            SECRET_KEY.encode("utf-8"), payload.encode("utf-8"), hashlib.sha256
        ).hexdigest()
        if not hmac.compare_digest(firma, firma_esperada):
            raise ValueError("firma invalida")

        datos = json.loads(base64.urlsafe_b64decode(payload + "=" * (-len(payload) % 4)))
        usuario_id = int(datos["sub"])
    except (ValueError, KeyError, TypeError, json.JSONDecodeError):
        raise HTTPException(status_code=401, detail="Token invalido")

    usuario = db.get(Usuario, usuario_id)
    if usuario is None:
        raise HTTPException(status_code=401, detail="Usuario no encontrado")

    return usuario
