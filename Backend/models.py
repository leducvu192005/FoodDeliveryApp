# models.py
from sqlalchemy import Column, Integer, String, Boolean, Float, ForeignKey, JSON, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship

Base = declarative_base()

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String)
    email = Column(String, unique=True, index=True)
    password_hash = Column(String(255))
    role = Column(String)
    is_active = Column(Boolean, default=True)


class Category(Base):
    __tablename__ = "category"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, nullable=False)
    
    # Relationship với Dish
    dishes = relationship("Dish", back_populates="category")


class Dish(Base):
    __tablename__ = "dish"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    img = Column(String, nullable=True)
    price = Column(Float, nullable=False)
    category_id = Column(Integer, ForeignKey("category.id"), nullable=False)
    description = Column(Text, nullable=True)
    group = Column(String, nullable=True)
    
    # Relationship với Category
    category = relationship("Category", back_populates="dishes")


class Topping(Base):
    __tablename__ = "topping"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    items = Column(JSON, nullable=True)  # Lưu danh sách topping items dưới dạng JSON
    dish_ids = Column(JSON, nullable=True)  # Lưu danh sách dish_ids dưới dạng JSON



