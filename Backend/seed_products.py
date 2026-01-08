# Backend/seed_products.py
from database import SessionLocal, engine
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
import time

products_to_insert = [
    {"name": "Bánh mì đặc biệt", "description": "Bánh mì thịt, pate, rau", "price": 35000.0, "image_url": ""},
    {"name": "Phở bò", "description": "Phở bò tái nạm", "price": 60000.0, "image_url": ""},
    {"name": "Trà sữa trân châu", "description": "Trà sữa thơm ngon", "price": 45000.0, "image_url": ""},
]

create_table_sql = """
CREATE TABLE IF NOT EXISTS products (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  price NUMERIC(10,2) NOT NULL,
  image_url TEXT,
  create_at INTEGER NOT NULL DEFAULT (EXTRACT(EPOCH FROM now())::integer)
);
"""

insert_sql = """
INSERT INTO products (name, description, price, image_url, create_at)
VALUES (:name, :description, :price, :image_url, :create_at)
ON CONFLICT DO NOTHING;
"""

def main():
    session = SessionLocal()
    try:
        # ensure table exists (creates create_at as integer epoch if table missing)
        session.execute(text(create_table_sql))
        # insert sample rows with create_at set to now()
        for p in products_to_insert:
            p['create_at'] = int(time.time())
            session.execute(text(insert_sql), p)
        session.commit()
        print("✅ Seed completed")
    except SQLAlchemyError as e:
        session.rollback()
        print("❌ Error:", e)
    finally:
        session.close()

if __name__ == "__main__":
    main()