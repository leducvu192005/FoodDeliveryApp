from sqlalchemy import create_engine, text

DATABASE_URL = "postgresql://postgres.pwwkqdizdbxvgpbysfgy:5*d?z_B?Vh#qdsF@aws-1-ap-southeast-1.pooler.supabase.com:5432/postgres"

engine = create_engine(DATABASE_URL)

try:
    with engine.connect() as conn:
        conn.execute(text("SELECT 1"))
        print("✅ CONNECT DB OK")
except Exception as e:
    print("❌ CONNECT FAIL")
    print(e)
