from sqlalchemy import inspect, text

from database import engine
from models import Base

def setup_shipper_tables():
    # Create new tables if they do not exist.
    Base.metadata.create_all(bind=engine)

    inspector = inspect(engine)
    if "orders" not in inspector.get_table_names():
        raise RuntimeError("orders table does not exist")

    alters = [
        "ALTER TABLE orders ADD COLUMN IF NOT EXISTS shipper_id INTEGER REFERENCES shippers(id)",
        "ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_fee DOUBLE PRECISION DEFAULT 0",
        "ALTER TABLE orders ADD COLUMN IF NOT EXISTS distance_km DOUBLE PRECISION DEFAULT 0",
        "ALTER TABLE orders ADD COLUMN IF NOT EXISTS pickup_address VARCHAR",
        "ALTER TABLE orders ADD COLUMN IF NOT EXISTS pickup_lat DOUBLE PRECISION",
        "ALTER TABLE orders ADD COLUMN IF NOT EXISTS pickup_lng DOUBLE PRECISION",
        "ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_address VARCHAR",
        "ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_lat DOUBLE PRECISION",
        "ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_lng DOUBLE PRECISION",
        "ALTER TABLE orders ADD COLUMN IF NOT EXISTS estimated_delivery_minutes INTEGER",
        "ALTER TABLE orders ADD COLUMN IF NOT EXISTS assigned_at TIMESTAMP",
        "ALTER TABLE orders ADD COLUMN IF NOT EXISTS picked_up_at TIMESTAMP",
        "ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMP",
        "ALTER TABLE pending_stripe_checkouts ADD COLUMN IF NOT EXISTS pickup_lat DOUBLE PRECISION",
        "ALTER TABLE pending_stripe_checkouts ADD COLUMN IF NOT EXISTS pickup_lng DOUBLE PRECISION",
        "ALTER TABLE pending_stripe_checkouts ADD COLUMN IF NOT EXISTS delivery_lat DOUBLE PRECISION",
        "ALTER TABLE pending_stripe_checkouts ADD COLUMN IF NOT EXISTS delivery_lng DOUBLE PRECISION",
        "ALTER TABLE profile ADD COLUMN IF NOT EXISTS lat DOUBLE PRECISION",
        "ALTER TABLE profile ADD COLUMN IF NOT EXISTS lng DOUBLE PRECISION",
        "ALTER TABLE shippers ADD COLUMN IF NOT EXISTS avatar VARCHAR",
        "ALTER TABLE shippers ADD COLUMN IF NOT EXISTS license_plate VARCHAR",
        "ALTER TABLE shippers ADD COLUMN IF NOT EXISTS lat DOUBLE PRECISION",
        "ALTER TABLE shippers ADD COLUMN IF NOT EXISTS lng DOUBLE PRECISION",
        "ALTER TABLE shippers ADD COLUMN IF NOT EXISTS last_location_update TIMESTAMP",
        "ALTER TABLE shippers ADD COLUMN IF NOT EXISTS accept_radius INTEGER DEFAULT 5",
        "ALTER TABLE shippers ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW()",
    ]

    with engine.begin() as connection:
        for alter in alters:
            connection.execute(text(alter))
        connection.execute(
            text(
                "CREATE INDEX IF NOT EXISTS idx_orders_shipper_status "
                "ON orders(shipper_id, status)"
            )
        )

    print("Shipper tables and order delivery columns are ready.")


if __name__ == "__main__":
    setup_shipper_tables()
