"""
Script để thêm cột transaction_id vào bảng payments
"""
from sqlalchemy import text
from database import engine

def add_transaction_id_column():
    try:
        with engine.connect() as conn:
            # Kiểm tra xem cột đã tồn tại chưa
            result = conn.execute(text("""
                SELECT column_name 
                FROM information_schema.columns 
                WHERE table_name='payments' AND column_name='transaction_id'
            """))
            
            if result.fetchone():
                print("✓ Cột transaction_id đã tồn tại")
                return
            
            # Thêm cột mới
            conn.execute(text("""
                ALTER TABLE payments 
                ADD COLUMN transaction_id VARCHAR(100) UNIQUE
            """))
            conn.commit()
            print("✓ Đã thêm cột transaction_id vào bảng payments")
            
    except Exception as e:
        print(f"✗ Lỗi: {e}")
        print("\nThử cách khác: Xóa và tạo lại database")
        print("Chạy: python create_db.py")

if __name__ == "__main__":
    add_transaction_id_column()
