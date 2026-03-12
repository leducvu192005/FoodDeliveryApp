from database import engine
from sqlalchemy import text

with engine.connect() as conn:
    result = conn.execute(text(
        "SELECT column_name FROM information_schema.columns "
        "WHERE table_name='payments' AND column_name='transaction_id'"
    ))
    if result.fetchall():
        print("Column transaction_id already exists")
    else:
        conn.execute(text("ALTER TABLE payments ADD COLUMN transaction_id VARCHAR NULL"))
        conn.commit()
        print("Column transaction_id added successfully")
