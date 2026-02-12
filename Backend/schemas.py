from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime
from uuid import UUID
class RegisterRequest(BaseModel):
    full_name: str
    email: EmailStr
    password: str
    role: str

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class UserResponse(BaseModel):
    id: int
    full_name: str
    email: str
    role: str

    class Config:
        from_attributes = True
class CouponCreate(BaseModel):
    code:str
    title: Optional[str] 
    description: Optional[str]
    discount_type: str
    discount_value: float
    min_order_value: Optional[float]
    start_at: Optional[datetime]
    end_at: Optional[datetime]


class ProductResponse(BaseModel):
    id: int 
    name: str
    description: str
    price: float
    image_url: Optional[str]
    create_at: int
    class Config:
        from_attributes = True
class ProductCreate(BaseModel):
    name: str
    description: str
    price: float
    image_url: Optional[str]
    create_at: int

class CouponResponse(BaseModel):
    id :int 
    code: str 
    title: Optional[str]
    description:Optional[str]
    discount_type: str
    discount_value:float
    min_order_value: float
    start_at: Optional[datetime]
    end_at: Optional[datetime]
    active:bool
    class Config:
        from_attributes =True
class CouponValidateRequest(BaseModel):
    code: str
    order_value: float
class CouponValidateResponse(BaseModel):
    valid: bool
    discount_value: float
    message: Optional[str]    
class DishResponse(BaseModel):
    id: int
    name: str
    price: float
    img: Optional[str]
    class Config:
        from_attributes = True

class CartItemCreate(BaseModel):
    dish_id: int
    quantity: int =1
class CartItemUpdate(BaseModel):
    quantity: int 
    dish_id: int


class CartItemResponse(BaseModel):
    id:int
    dish_id: int
    quantity: int 
    dish: DishResponse
    class Config:
        from_attributes = True


class CategoryCreate(BaseModel):
    name: str
    description: Optional[str] = None
    image: Optional[str] = None

class CategoryResponse(BaseModel):
    id: int
    name: str
    description: Optional[str] = None
    image: Optional[str] = None

    class Config:
        from_attributes = True


class CartCheckoutRequest(BaseModel):
    method: str


class CartCheckoutResponse(BaseModel):
    order_id: int
    total_amount: float
    payment_method: str
    payment_status: str
    payment_url: Optional[str] = None
    message: str
class PaymentCreateRequest(BaseModel):
    order_id: int


class PaymentResponse(BaseModel):
    client_secret: str
    payment_id: int


class PaymentStatusResponse(BaseModel):
    status: str
