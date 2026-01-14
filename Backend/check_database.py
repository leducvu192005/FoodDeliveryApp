from database import engine, DATABASE_URL
from sqlalchemy import text

print("🔍 KIỂM TRA DATABASE ĐANG KẾT NỐI\n")

# 1. Hiển thị DATABASE_URL (ẩn password)
print("📡 Connection String:")
if '@' in DATABASE_URL:
    parts = DATABASE_URL.split('@')
    user_part = parts[0].split('://')[1].split(':')[0]
    host_part = parts[1]
    print(f"  User: {user_part}")
    print(f"  Host: {host_part}\n")
else:
    print(f"  {DATABASE_URL}\n")

# 2. Kiểm tra tên database hiện tại
with engine.connect() as conn:
    result = conn.execute(text("SELECT current_database()"))
    db_name = result.scalar()
    print(f"📂 Database đang kết nối: {db_name}\n")
    
    # 3. Liệt kê tất cả bảng trong database này
    result = conn.execute(text("""
        SELECT schemaname, tablename 
        FROM pg_tables 
        WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
        ORDER BY schemaname, tablename
    """))
    
    print("📋 Tất cả bảng trong database:")
    tables_by_schema = {}
    for row in result:
        schema = row[0]
        table = row[1]
        if schema not in tables_by_schema:
            tables_by_schema[schema] = []
        tables_by_schema[schema].append(table)
    
    for schema, tables in tables_by_schema.items():
        print(f"\n  Schema: {schema}")
        for table in tables:
            print(f"    ✓ {table}")
    
    # 4. Kiểm tra cụ thể 6 bảng của chúng ta
    print("\n\n🔎 Kiểm tra 6 bảng cần thiết:")
    expected_tables = ['users', 'products', 'coupons', 'category', 'dish', 'topping']
    for table in expected_tables:
        result = conn.execute(text(f"""
            SELECT table_schema, table_name 
            FROM information_schema.tables 
            WHERE table_name = '{table}'
            AND table_schema NOT IN ('pg_catalog', 'information_schema')
        """))
        rows = result.fetchall()
        if rows:
            for row in rows:
                print(f"  ✓ {table} → schema: {row[0]}, database: {db_name}")
        else:
            print(f"  ✗ {table} → KHÔNG TÌM THẤY trong database {db_name}")

print(f"\n\n💡 Trong pgAdmin4, hãy đảm bảo bạn đang xem:")
print(f"   - Database: {db_name}")
print(f"   - Schema: public (hoặc schema khác nếu thấy ở trên)")
