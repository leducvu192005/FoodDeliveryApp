import os
from pathlib import Path
from urllib.parse import quote_plus

from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import sessionmaker

ENV_PATH = Path(__file__).resolve().parent / ".env"
load_dotenv(ENV_PATH)


def _clean_env(value: str | None) -> str | None:
    if value is None:
        return None
    cleaned = value.strip().strip('"').strip("'")
    return cleaned or None


def _normalize_url(url: str) -> str:
    if url.startswith("postgres://"):
        return url.replace("postgres://", "postgresql+psycopg2://", 1)
    if url.startswith("postgresql://"):
        return url.replace("postgresql://", "postgresql+psycopg2://", 1)
    return url


def _build_local_database_url() -> str | None:
    host = _clean_env(os.getenv("DB_HOST"))
    name = _clean_env(os.getenv("DB_NAME"))
    user = _clean_env(os.getenv("DB_USER") or os.getenv("Db_USER"))
    password = _clean_env(os.getenv("DB_PASSWORD"))
    port = _clean_env(os.getenv("DB_PORT")) or "5432"

    if not all([host, name, user, password]):
        return None

    return (
        "postgresql+psycopg2://"
        f"{quote_plus(user)}:{quote_plus(password)}@{host}:{port}/{quote_plus(name)}"
    )


def _candidate_database_urls() -> list[str]:
    candidates: list[str] = []

    for env_name in ("DATABASE_URL", "DB_URL"):
        raw_value = _clean_env(os.getenv(env_name))
        if not raw_value:
            continue
        if "[YOUR-PASSWORD]" in raw_value:
            continue

        normalized = _normalize_url(raw_value)
        if normalized not in candidates:
            candidates.append(normalized)

    local_url = _build_local_database_url()
    if local_url and local_url not in candidates:
        candidates.append(local_url)

    return candidates


def _safe_database_label(url: str) -> str:
    try:
        without_scheme = url.split("://", 1)[1]
        credentials, host_part = without_scheme.split("@", 1)
        username = credentials.split(":", 1)[0]
        return f"{username}@{host_part}"
    except (IndexError, ValueError):
        return "<invalid-database-url>"


def _create_engine(url: str):
    connect_args = {}
    if "supabase.com" in url:
        connect_args["sslmode"] = "require"

    return create_engine(
        url,
        pool_pre_ping=True,
        connect_args=connect_args,
    )


def _resolve_engine():
    candidates = _candidate_database_urls()
    if not candidates:
        raise ValueError(
            "No usable database configuration found. Set DATABASE_URL or DB_HOST/DB_NAME/DB_USER/DB_PASSWORD."
        )

    failures: list[str] = []

    for candidate in candidates:
        candidate_engine = _create_engine(candidate)
        try:
            with candidate_engine.connect() as connection:
                connection.execute(text("SELECT 1"))
            return candidate_engine, candidate
        except SQLAlchemyError as exc:
            candidate_engine.dispose()
            failures.append(f"{_safe_database_label(candidate)} -> {exc.__class__.__name__}: {exc}")

    joined_failures = "\n".join(failures)
    raise RuntimeError(
        "Could not connect to any configured database.\n"
        f"Tried:\n{joined_failures}"
    )


engine, DATABASE_URL = _resolve_engine()

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
