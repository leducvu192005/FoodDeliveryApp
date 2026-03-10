"""Migrate: tạo bản ghi sellers cho các user role='seller' đã tồn tại."""
from database import engine
from sqlalchemy import text


def migrate_existing_sellers():
    with engine.connect() as conn:
        result = conn.execute(text(
            "INSERT INTO sellers (user_id, name, status, address, phone, email) "
            "SELECT u.id, COALESCE(u.name_shop, u.full_name), 'off', u.address, u.sdt, u.email "
            "FROM users u "
            "WHERE u.role = 'seller' "
            "AND u.id NOT IN (SELECT user_id FROM sellers) "
            "RETURNING id, user_id, name"
        ))
        rows = result.fetchall()
        conn.commit()
        print(f"Inserted {len(rows)} seller records:")
        for r in rows:
            print(f"  id={r[0]} user_id={r[1]} name={r[2]}")


if __name__ == "__main__":
    migrate_existing_sellers()
