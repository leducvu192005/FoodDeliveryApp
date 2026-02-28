from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime
from uuid import UUID
class RegisterRequest(BaseModel):
    full_name: str
    email: EmailStr
    sdt : str
    password: str
    role: str

class LoginRequest(BaseModel):
    email: EmailStr
    sdt : str
    password: str

class UserResponse(BaseModel):
    id: int
    full_name: str
    email: str
    sdt: str
    role: str

    class Config:
        from_attributes = True

class DiscountCodeCreate(BaseModel):
    code:str
    title: Optional[str] 
    description: Optional[str]
    discount_type: str
    discount_value: float
    min_order_value: Optional[float]
    start_at: Optional[datetime]
    end_at: Optional[datetime]
    user_id: Optional[int] = None  # None = áp dụng cho tất cả user


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

class DiscountCodeResponse(BaseModel):
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
    user_id: Optional[int] = None
    class Config:
        from_attributes =True

class DiscountCodeUpdate(BaseModel):
    code: Optional[str] = None
    title: Optional[str] = None
    description: Optional[str] = None
    discount_type: Optional[str] = None
    discount_value: Optional[float] = None
    min_order_value: Optional[float] = None
    start_at: Optional[datetime] = None
    end_at: Optional[datetime] = None
    active: Optional[bool] = None
    user_id: Optional[int] = None

class DiscountCodeValidateRequest(BaseModel):
    code: str
    cart_total: float

class DiscountCodeValidateResponse(BaseModel):
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

class CategoryResponse(BaseModel):
    id: int
    name: str

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
