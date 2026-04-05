from sqlalchemy import text

from database import engine


def setup_user_columns() -> None:
    statements = [
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS sdt VARCHAR(15)",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS address VARCHAR",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS lat DOUBLE PRECISION",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS lng DOUBLE PRECISION",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS cccd NUMERIC",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS vehicle_registration NUMERIC",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS license NUMERIC",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS name_shop VARCHAR",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS address_shop VARCHAR",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS status VARCHAR",
    ]

    with engine.begin() as connection:
        for statement in statements:
            connection.execute(text(statement))
