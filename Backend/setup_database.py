import psycopg2

def setup_database():
    """Tạo bảng dish trong database"""
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
        
        # Tạo bảng dish
        print("Đang tạo bảng dish...")
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS dish (
                id SERIAL PRIMARY KEY,
                name VARCHAR(255) NOT NULL,
                img TEXT,
                price NUMERIC(12, 2) NOT NULL,
                category_id INTEGER,
                description TEXT,
                "group" VARCHAR(100),
                CONSTRAINT fk_category 
                    FOREIGN KEY (category_id) 
                    REFERENCES category(id)
                    ON DELETE SET NULL
            );
        """)
        
        # Tạo indexes
        print("Đang tạo indexes...")
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_dish_category_id ON dish(category_id);
        """)
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_dish_name ON dish(name);
        """)
        
        connection.commit()
        print("✅ Tạo bảng dish thành công!")
        
        # Kiểm tra bảng đã được tạo
        cursor.execute("""
            SELECT column_name, data_type, character_maximum_length, is_nullable
            FROM information_schema.columns
            WHERE table_name = 'dish'
            ORDER BY ordinal_position;
        """)
        
        print("\n📋 Cấu trúc bảng dish:")
        print("-" * 70)
        print(f"{'Cột':<20} {'Kiểu dữ liệu':<25} {'Độ dài':<10} {'NULL?'}")
        print("-" * 70)
        for row in cursor.fetchall():
            col_name, data_type, max_length, nullable = row
            length_str = str(max_length) if max_length else "-"
            print(f"{col_name:<20} {data_type:<25} {length_str:<10} {nullable}")
        
        cursor.close()
        
    except Exception as error:
        print(f"❌ Lỗi: {error}")
        if connection:
            connection.rollback()
    finally:
        if connection:
            connection.close()
            print("\nĐã đóng kết nối database.")

if __name__ == "__main__":
    setup_database()
