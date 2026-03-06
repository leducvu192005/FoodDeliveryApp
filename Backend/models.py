# models.py
from sqlalchemy import Column, Integer, String, Boolean, Float, ForeignKey, JSON, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from sqlalchemy.sql import  func
from sqlalchemy import Column, Integer, String, Boolean, Numeric,ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.types import DateTime as Datetime 
Base = declarative_base()

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String)
    email = Column(String, unique=True, index=True)
    sdt = Column(String(15))
    password_hash = Column(String(255))
    role = Column(String)
    is_active = Column(Boolean, default=True)


class Category(Base):
    __tablename__ = "category"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    seller_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # Relationship với Dish
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
    
    # Relationship với Category
    category = relationship("Category", back_populates="dishes")
    seller = relationship("User", foreign_keys=[seller_id])


class Topping(Base):
    __tablename__ = "topping"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    seller_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    min = Column(Integer, default=0)
    max = Column(Integer, default=1)
    items = Column(JSON, nullable=True)  # Lưu danh sách topping items dưới dạng JSON
    dish_ids = Column(JSON, nullable=True)  # Lưu danh sách dish_ids dưới dạng JSON
    
    seller = relationship("User", foreign_keys=[seller_id])



class Product(Base):
    __tablename__ = "products"
    id = Column(Integer, primary_key = True, index = True)
    name = Column(String, nullable = False)
    description = Column(String, nullable = False)
    price = Column(Numeric(10,2), nullable =False)
    image_url = Column(String, nullable =True)
    create_at = Column(Integer, nullable =False)

class DiscountCode(Base):
    __tablename__ = "discount_code"

    id = Column(Integer, primary_key=True, index=True)
    code = Column(String, unique=True, index=True)
    title = Column(String, nullable=True)
    description = Column(String, nullable=True)
    discount_type = Column(String, nullable=False)
    discount_value = Column(Numeric(10,2), nullable=False)
    min_order_value = Column(Numeric(10,2), nullable=True)
    start_at = Column(Datetime, nullable=True)
    end_at = Column(Datetime, nullable=True)
    active = Column(Boolean, default=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)  # NULL = áp dụng cho tất cả user
    create_by = Column(Integer,nullable=False)
    create_at = Column(Datetime, server_default=func.now())


class Profile(Base):
    __tablename__ = "profile"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)  # Tên quán
    
    sdt = Column(String, nullable=True)  # Số điện thoại
    live = Column(String, nullable=True)  # Địa chỉ
    img = Column(Text, nullable=True)  # Ảnh đại diện 
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)  # Liên kết với User 
class CartItem(Base):
    __tablename__ ='cart_items'
    
    id = Column(Integer,primary_key=True,index=True)
    user_id = Column(Integer,ForeignKey("users.id"))
    dish_id =Column(Integer,ForeignKey("dish.id"))
    quantity = Column(Integer,default=1)
    dish = relationship("Dish")
class Order(Base):
    __tablename__ ='orders'
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    seller_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    total_price = Column(Float)
    status = Column(String, default = "pending")
    payment_method = Column(String)
    created_at = Column(Datetime, server_default=func.now())
class OrderItem(Base):
    __tablename__ = 'order_items'
    id = Column(Integer, primary_key= True, index = True)
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
    transaction_id = Column(String, nullable=True, unique=True)  # For Sepay transactions

    paid_at = Column(Datetime, nullable=True)
    created_at = Column(Datetime, server_default=func.now())

    order = relationship("Order")
class Shipper(Base):
    __tablename__ = "shippers"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id =Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True)
    full_name = Column(String, nullable=False)
    phone = Column(String, nullable=False)
    verhice_type = Column(String, nullable=False)
    is_online = Column(Boolean, default=False)
    rating = Column(Numeric(2,1), default=0.0)
    total_completed_orders = Column(Integer, default=0)
    created_at = Column(Datetime, server_default=func.now())
    user = relationship("User")