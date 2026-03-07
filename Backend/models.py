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
    create_by = Column(Integer, nullable=False)
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
    paid_at = Column(Datetime, nullable=True)
    created_at = Column(Datetime, server_default=func.now())

    order = relationship("Order")


class PendingStripeCheckout(Base):
    __tablename__ = "pending_stripe_checkouts"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
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
    status = Column(String, default="pending")
    payment_intent_id = Column(String, nullable=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"), nullable=True)
    cart_snapshot = Column(JSON, nullable=False)
    completed_at = Column(Datetime, nullable=True)
    created_at = Column(Datetime, server_default=func.now())


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
    updated_at = Column(Datetime, server_default=func.now(), onupdate=func.now())
    created_at = Column(Datetime, server_default=func.now())
    user = relationship("User")


class ShipperSession(Base):
    __tablename__ = "shipper_sessions"

    id = Column(Integer, primary_key=True, index=True)
    shipper_id = Column(Integer, ForeignKey("shippers.id", ondelete="CASCADE"), nullable=False)
    start_time = Column(Datetime, server_default=func.now(), nullable=False)
    end_time = Column(Datetime, nullable=True)
