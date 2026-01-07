import psycopg2

def update_topping_table():
    """Cập nhật bảng topping: đổi cột price thành items"""
    connection = None
    try:
        # Kết nối database
        connection = psycopg2.connect(
            host="localhost",          
            database="FoodDeliveryApp", 
            user="postgres",          
            password="NKLog0204205@", 
            port="5432"
        )
        
        cursor = connection.cursor()
        
        # Kiểm tra xem cột items đã tồn tại chưa
        cursor.execute("""
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'topping' AND column_name = 'items';
        """)
        
        if cursor.fetchone() is None:
            print("Đang thêm cột items...")
            # Xóa cột price và thêm cột items
            cursor.execute("""
                ALTER TABLE topping DROP COLUMN IF EXISTS price;
            """)
            cursor.execute("""
                ALTER TABLE topping ADD COLUMN items JSONB DEFAULT '[]'::jsonb;
            """)
            connection.commit()
            print("✅ Cập nhật bảng topping thành công!")
        else:
            print("✅ Cột items đã tồn tại!")
        
        # Kiểm tra cấu trúc bảng
        cursor.execute("""
            SELECT column_name, data_type, character_maximum_length, is_nullable
            FROM information_schema.columns
            WHERE table_name = 'topping'
            ORDER BY ordinal_position;
        """)
        
        print("\n📋 Cấu trúc bảng topping:")
        columns = cursor.fetchall()
        for col in columns:
            print(f"   - {col[0]}: {col[1]}" + (f"({col[2]})" if col[2] else "") + f" - {'NULL' if col[3] == 'YES' else 'NOT NULL'}")
        
        cursor.close()
        
    except (Exception, psycopg2.Error) as error:
        print(f"❌ Lỗi: {error}")
        if connection:
            connection.rollback()
    finally:
        if connection:
            connection.close()

if __name__ == "__main__":
    update_topping_table()
