"""Migration: tạo bảng sellers nếu chưa tồn tại."""
from database import engine


def setup_sellers_table():
    with engine.connect() as conn:
        conn.execute(
            __import__("sqlalchemy").text("""
                CREATE TABLE IF NOT EXISTS sellers (
                    id SERIAL PRIMARY KEY,
                    user_id INTEGER NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
                    name VARCHAR(255) NOT NULL,
                    status VARCHAR(10) DEFAULT 'off',
                    address TEXT,
                    phone VARCHAR(20),
                    email VARCHAR(255),
                    cccd VARCHAR(20),
                    lat FLOAT,
                    lng FLOAT,
                    price FLOAT DEFAULT 0,
                    created_at TIMESTAMP DEFAULT NOW()
                );
            """)
        )
        conn.commit()
    print("Sellers table ready.")


if __name__ == "__main__":
    setup_sellers_table()
