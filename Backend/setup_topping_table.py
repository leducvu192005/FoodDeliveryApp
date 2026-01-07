import psycopg2

def setup_topping_table():
    """Tạo bảng topping trong database"""
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
        
        # Tạo bảng topping
        print("Đang tạo bảng topping...")
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS topping (
                id SERIAL PRIMARY KEY,
                name VARCHAR(255) NOT NULL UNIQUE,
                price DECIMAL(10, 2) DEFAULT 0,
                dish_ids INTEGER[] DEFAULT ARRAY[]::INTEGER[],
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)
        
        # Tạo indexes
        print("Đang tạo indexes...")
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_topping_name ON topping(name);
        """)
        
        # Tạo trigger function
        print("Đang tạo trigger function...")
        cursor.execute("""
            CREATE OR REPLACE FUNCTION update_topping_updated_at()
            RETURNS TRIGGER AS $$
            BEGIN
                NEW.updated_at = CURRENT_TIMESTAMP;
                RETURN NEW;
            END;
            $$ LANGUAGE plpgsql;
        """)
        
        # Tạo trigger
        print("Đang tạo trigger...")
        cursor.execute("""
            DROP TRIGGER IF EXISTS trigger_update_topping_timestamp ON topping;
        """)
        cursor.execute("""
            CREATE TRIGGER trigger_update_topping_timestamp
                BEFORE UPDATE ON topping
                FOR EACH ROW
                EXECUTE FUNCTION update_topping_updated_at();
        """)
        
        connection.commit()
        print("✅ Tạo bảng topping thành công!")
        
        # Kiểm tra bảng đã được tạo
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
    setup_topping_table()
