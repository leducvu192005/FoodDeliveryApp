# models.py
from sqlalchemy import Boolean, Column, Float, ForeignKey, Integer, JSON, Numeric, String, Text, UniqueConstraint
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from sqlalchemy.types import DateTime as Datetime

Base = declarative_base()


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String)
    email = Column(String, unique=True, index=True)
    sdt = Column(String(15))
    address = Column(String, nullable=True)
    lat = Column(Float, nullable=True)
    lng = Column(Float, nullable=True)
    password_hash = Column(String(255))
    role = Column(String)
    is_active = Column(Boolean, default=True)
    cccd = Column(Numeric, nullable=True)
    vehicle_registration = Column(Numeric, nullable=True)
    license = Column(Numeric, nullable=True)
    name_shop = Column(String, nullable=True)
    address_shop = Column(String, nullable=True)
    status = Column(String, nullable=True)


class PasswordReset(Base):
    __tablename__ = "password_resets"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, nullable=False)
    otp = Column(String(6), nullable=False)
    expires_at = Column(Datetime, nullable=False)
    used = Column(Boolean, default=False)


class Category(Base):
    __tablename__ = "category"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    seller_id = Column(Integer, ForeignKey("users.id"), nullable=False)

    dishes = relationship("Dish", back_populates="category")
    seller = relationship("User", foreign_keys=[seller_id])


class Dish(Base):
    __tablename__ = "dish"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    img = Column(String, nullable=True)
    price = Column(Float, nullable=False)
    category_id = Column(Integer, ForeignKey("category.id"), nullable=False)
    seller_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    description = Column(Text, nullable=True)
    group = Column(String, nullable=True)

    category = relationship("Category", back_populates="dishes")
    seller = relationship("User", foreign_keys=[seller_id])


class Topping(Base):
    __tablename__ = "topping"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    seller_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    min = Column(Integer, default=0)
    max = Column(Integer, default=1)
    items = Column(JSON, nullable=True)
    dish_ids = Column(JSON, nullable=True)

    seller = relationship("User", foreign_keys=[seller_id])


class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    description = Column(String, nullable=False)
    price = Column(Numeric(10, 2), nullable=False)
    image_url = Column(String, nullable=True)
    create_at = Column(Integer, nullable=False)


class DiscountCode(Base):
    __tablename__ = "discount_code"

    id = Column(Integer, primary_key=True, index=True)
    code = Column(String, unique=True, index=True)
    title = Column(String, nullable=True)
    description = Column(String, nullable=True)
    discount_type = Column(String, nullable=False)
    discount_value = Column(Numeric(10, 2), nullable=False)
    min_order_value = Column(Numeric(10, 2), nullable=True)
    start_at = Column(Datetime, nullable=True)
    end_at = Column(Datetime, nullable=True)
    active = Column(Boolean, default=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    seller_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    create_by = Column(Integer, nullable=True)
    create_at = Column(Datetime, server_default=func.now())


class Profile(Base):
    __tablename__ = "profile"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    sdt = Column(String, nullable=True)
    live = Column(String, nullable=True)
    lat = Column(Float, nullable=True)
    lng = Column(Float, nullable=True)
    img = Column(Text, nullable=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)


class CartItem(Base):
    __tablename__ = "cart_items"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    dish_id = Column(Integer, ForeignKey("dish.id"))
    quantity = Column(Integer, default=1)
    dish = relationship("Dish")


class Favorite(Base):
    __tablename__ = "favorites"
    __table_args__ = (
        UniqueConstraint("user_id", "dish_id", name="uq_favorites_user_dish"),
    )

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    dish_id = Column(Integer, ForeignKey("dish.id", ondelete="CASCADE"), nullable=False, index=True)
    created_at = Column(Datetime, server_default=func.now(), nullable=False)

    user = relationship("User")
    dish = relationship("Dish")


class Order(Base):
    __tablename__ = "orders"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    shipper_id = Column(Integer, ForeignKey("shippers.id"), nullable=True)
    seller_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    total_price = Column(Float)
    delivery_fee = Column(Float, default=0)
    discount_amount = Column(Float, default=0)
    distance_km = Column(Float, default=0)
    pickup_address = Column(String, nullable=True)
    pickup_lat = Column(Float, nullable=True)
    pickup_lng = Column(Float, nullable=True)
    delivery_address = Column(String, nullable=True)
    delivery_lat = Column(Float, nullable=True)
    delivery_lng = Column(Float, nullable=True)
    estimated_delivery_minutes = Column(Integer, nullable=True)
    status = Column(String, default="pending")
    payment_method = Column(String)
    note = Column(Text, nullable=True)
    assigned_at = Column(Datetime, nullable=True)
    picked_up_at = Column(Datetime, nullable=True)
    delivered_at = Column(Datetime, nullable=True)
    created_at = Column(Datetime, server_default=func.now())


class OrderItem(Base):
    __tablename__ = "order_items"

    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"))
    dish_id = Column(Integer)
    dish_name = Column(String)
    dish_image = Column(String)
    dish_price = Column(Float)
    quantity = Column(Integer)


class Payment(Base):
    __tablename__ = "payments"

    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"))
    amount = Column(Float, nullable=False)
    method = Column(String)
    status = Column(String, default="pending")
    stripe_payment_intent = Column(String, nullable=True)
    transaction_id = Column(String, nullable=True)
    paid_at = Column(Datetime, nullable=True)
    created_at = Column(Datetime, server_default=func.now())

    order = relationship("Order")


class Shipper(Base):
    __tablename__ = "shippers"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True)
    full_name = Column(String, nullable=False)
    phone = Column(String, nullable=False)
    avatar = Column(String, nullable=True)
    verhice_type = Column(String, nullable=False)
    license_plate = Column(String, nullable=True)
    is_online = Column(Boolean, default=False)
    lat = Column(Float, nullable=True)
    lng = Column(Float, nullable=True)
    last_location_update = Column(Datetime, nullable=True)
    accept_radius = Column(Integer, default=5)
    rating = Column(Numeric(2, 1), default=0.0)
    total_completed_orders = Column(Integer, default=0)
    price = Column(Float, default=0)
    updated_at = Column(Datetime, server_default=func.now(), onupdate=func.now())
    created_at = Column(Datetime, server_default=func.now())
    user = relationship("User")


class PendingStripeCheckout(Base):
    __tablename__ = "pending_stripe_checkouts"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    payment_intent_id = Column(String, nullable=True)
    client_secret = Column(String, nullable=True)
    total_price = Column(Float, nullable=False)
    delivery_fee = Column(Float, default=0)
    distance_km = Column(Float, default=0)
    pickup_address = Column(String, nullable=True)
    pickup_lat = Column(Float, nullable=True)
    pickup_lng = Column(Float, nullable=True)
    delivery_address = Column(String, nullable=True)
    delivery_lat = Column(Float, nullable=True)
    delivery_lng = Column(Float, nullable=True)
    estimated_delivery_minutes = Column(Integer, nullable=True)
    seller_id = Column(Integer, nullable=True)
    cart_snapshot = Column(JSON, nullable=True)
    note = Column(Text, nullable=True)
    status = Column(String, default="pending")
    order_id = Column(Integer, ForeignKey("orders.id"), nullable=True)
    completed_at = Column(Datetime, nullable=True)
    created_at = Column(Datetime, server_default=func.now())


class ShipperSession(Base):
    __tablename__ = "shipper_sessions"

    id = Column(Integer, primary_key=True, index=True)
    shipper_id = Column(Integer, ForeignKey("shippers.id", ondelete="CASCADE"), nullable=False)
    start_time = Column(Datetime, server_default=func.now(), nullable=False)
    end_time = Column(Datetime, nullable=True)


class FormSeller(Base):
    __tablename__ = "form_seller"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    name = Column(String(255), nullable=False)
    phone = Column(String(20), nullable=False)
    email = Column(String(255), nullable=True)
    cccd = Column(String(20), nullable=False)
    name_shop = Column(String(255), nullable=False)
    address = Column(Text, nullable=False)
    status = Column(String(20), default="pending")
    created_at = Column(Datetime, server_default=func.now())


class FormShipper(Base):
    __tablename__ = "form_shipper"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    name = Column(String(255), nullable=False)
    phone = Column(String(20), nullable=False)
    email = Column(String(255), nullable=True)
    cccd = Column(String(20), nullable=False)
    vehicle_registration = Column(String(50), nullable=False)
    license = Column(String(50), nullable=False)
    status = Column(String(20), default="pending")
    created_at = Column(Datetime, server_default=func.now())


class Seller(Base):
    __tablename__ = "sellers"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    name = Column(String(255), nullable=False)
    status = Column(String(10), default="off")
    address = Column(Text, nullable=True)
    phone = Column(String(20), nullable=True)
    email = Column(String(255), nullable=True)
    cccd = Column(String(20), nullable=True)
    lat = Column(Float, nullable=True)
    lng = Column(Float, nullable=True)
    price = Column(Float, default=0)
    created_at = Column(Datetime, server_default=func.now())

    user = relationship("User")


class HistoryPriceSeller(Base):
    __tablename__ = "history_price_seller"

    id = Column(Integer, primary_key=True, index=True)
    seller_id = Column(Integer, ForeignKey("sellers.id", ondelete="CASCADE"), nullable=False)
    amount = Column(Float, nullable=False)
    balance_before = Column(Float, nullable=False)
    balance_after = Column(Float, nullable=False)
    note = Column(Text, nullable=True)
    status = Column(String(20), default="completed")
    created_at = Column(Datetime, server_default=func.now())

    seller = relationship("Seller")


class HistoryPriceShipper(Base):
    __tablename__ = "history_price_shipper"

    id = Column(Integer, primary_key=True, index=True)
    shipper_id = Column(Integer, ForeignKey("shippers.id", ondelete="CASCADE"), nullable=False)
    type = Column(String(20), default="withdraw")
    amount = Column(Float, nullable=False)
    balance_before = Column(Float, nullable=False)
    balance_after = Column(Float, nullable=False)
    note = Column(Text, nullable=True)
    status = Column(String(20), default="completed")
    created_at = Column(Datetime, server_default=func.now())

    shipper = relationship("Shipper")


class PendingShipperDeposit(Base):
    __tablename__ = "pending_shipper_deposits"

    id = Column(Integer, primary_key=True, index=True)
    shipper_id = Column(Integer, ForeignKey("shippers.id", ondelete="CASCADE"), nullable=False)
    amount = Column(Float, nullable=False)
    transaction_id = Column(String(50), unique=True, nullable=False)
    status = Column(String(20), default="pending")
    paid_at = Column(Datetime, nullable=True)
    created_at = Column(Datetime, server_default=func.now())

    shipper = relationship("Shipper")


class DisplayProgram(Base):
    __tablename__ = "display_programs"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    program_type = Column(String(50), default="featured")
    icon = Column(String(50), default="star")
    color = Column(String(20), default="#FF5722")
    start_date = Column(Datetime, nullable=False)
    end_date = Column(Datetime, nullable=False)
    is_active = Column(Boolean, default=True)
    max_sellers = Column(Integer, default=0)
    created_at = Column(Datetime, server_default=func.now())


class DisplayProgramSeller(Base):
    __tablename__ = "display_program_sellers"

    id = Column(Integer, primary_key=True, index=True)
    program_id = Column(Integer, ForeignKey("display_programs.id", ondelete="CASCADE"), nullable=False)
    seller_id = Column(Integer, ForeignKey("sellers.id", ondelete="CASCADE"), nullable=False)
    status = Column(String(20), default="joined")
    dish_show = Column(JSON, default=[])
    joined_at = Column(Datetime, server_default=func.now())

    program = relationship("DisplayProgram")
    seller = relationship("Seller")
