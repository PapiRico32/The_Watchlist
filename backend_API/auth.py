import logging
import os
import secrets
from datetime import datetime, timedelta, timezone
from typing import Any

from dotenv import load_dotenv
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from database import get_db
from models import Usuario

load_dotenv()

logger = logging.getLogger(__name__)
_secret_key = os.getenv("JWT_SECRET_KEY")
if not _secret_key:
    _secret_key = secrets.token_urlsafe(32)
    logger.warning(
        "JWT_SECRET_KEY no está configurada; los tokens dejarán de ser "
        "válidos al reiniciar el servidor. Configúrala en el entorno."
    )

_algorithm = os.getenv("JWT_ALGORITHM", "HS256")
_token_expiration_minutes = int(os.getenv("JWT_EXPIRATION_MINUTES", "10080"))

password_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


def hash_password(password: str) -> str:
    return password_context.hash(password)


def verificar_password(password: str, password_hash: str) -> bool:
    return password_context.verify(password, password_hash)


def crear_token(datos: dict[str, Any]) -> str:
    contenido = datos.copy()
    contenido["exp"] = datetime.now(timezone.utc) + timedelta(
        minutes=_token_expiration_minutes
    )
    return jwt.encode(contenido, _secret_key, algorithm=_algorithm)


def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> Usuario:
    no_autorizado = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="La sesión no es válida o ha expirado",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        payload = jwt.decode(token, _secret_key, algorithms=[_algorithm])
        subject = payload.get("sub")
        if not isinstance(subject, str):
            raise no_autorizado
        id_usuario = int(subject)
    except (JWTError, ValueError):
        raise no_autorizado from None

    usuario = db.query(Usuario).filter(Usuario.id_usr == id_usuario).first()
    if usuario is None or usuario.estatus == 0:
        raise no_autorizado

    return usuario
