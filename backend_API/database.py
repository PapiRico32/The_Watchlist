import os
from collections.abc import Generator

from dotenv import load_dotenv
from sqlalchemy import URL, create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

load_dotenv()


def _crear_url_base_datos() -> str | URL:
    url_configurada = os.getenv("DATABASE_URL")
    if url_configurada:
        return url_configurada

    return URL.create(
        drivername="mysql+pymysql",
        username=os.getenv("MYSQL_USER", "root"),
        password=os.getenv("MYSQL_PASSWORD", ""),
        host=os.getenv("MYSQL_HOST", "127.0.0.1"),
        port=int(os.getenv("MYSQL_PORT", "3306")),
        database=os.getenv("MYSQL_DATABASE", "blog_db"),
        query={"charset": "utf8mb4"},
    )


engine = create_engine(
    _crear_url_base_datos(),
    pool_pre_ping=True,
    pool_recycle=1800,
)

SessionLocal = sessionmaker(
    bind=engine,
    autocommit=False,
    autoflush=False,
)

Base = declarative_base()


def get_db() -> Generator:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
