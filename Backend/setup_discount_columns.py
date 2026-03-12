from sqlalchemy import inspect, text

from database import engine


def setup_discount_columns() -> None:
    """Add seller_id and create_by columns to discount_code table if missing.
    Also add discount_amount to orders table if missing."""
    inspector = inspect(engine)

    if "discount_code" in inspector.get_table_names():
        with engine.begin() as conn:
            conn.execute(
                text(
                    "ALTER TABLE discount_code ADD COLUMN IF NOT EXISTS seller_id INTEGER REFERENCES users(id)"
                )
            )
            conn.execute(
                text(
                    "ALTER TABLE discount_code ADD COLUMN IF NOT EXISTS create_by INTEGER"
                )
            )

    if "orders" in inspector.get_table_names():
        with engine.begin() as conn:
            conn.execute(
                text(
                    "ALTER TABLE orders ADD COLUMN IF NOT EXISTS discount_amount FLOAT DEFAULT 0"
                )
            )
