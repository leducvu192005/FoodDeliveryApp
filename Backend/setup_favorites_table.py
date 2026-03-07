from sqlalchemy import inspect, text

from database import engine


def setup_favorites_table() -> None:
    inspector = inspect(engine)
    if "favorites" not in inspector.get_table_names():
        with engine.begin() as conn:
            conn.execute(
                text(
                    """
                    CREATE TABLE IF NOT EXISTS favorites (
                        id SERIAL PRIMARY KEY,
                        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                        dish_id INTEGER NOT NULL REFERENCES dish(id) ON DELETE CASCADE,
                        created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
                        CONSTRAINT uq_favorites_user_dish UNIQUE (user_id, dish_id)
                    )
                    """
                )
            )

    with engine.begin() as conn:
        conn.execute(
            text(
                """
                CREATE INDEX IF NOT EXISTS ix_favorites_user_id ON favorites (user_id)
                """
            )
        )
        conn.execute(
            text(
                """
                CREATE INDEX IF NOT EXISTS ix_favorites_dish_id ON favorites (dish_id)
                """
            )
        )
