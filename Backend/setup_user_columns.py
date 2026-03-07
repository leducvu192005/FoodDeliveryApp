from sqlalchemy import text

from database import engine


def setup_user_columns() -> None:
    statements = [
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS address VARCHAR",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS lat DOUBLE PRECISION",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS lng DOUBLE PRECISION",
    ]

    with engine.begin() as connection:
        for statement in statements:
            connection.execute(text(statement))
