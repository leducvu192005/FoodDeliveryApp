from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime
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
        orm_mode = True
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
        from_orm = True
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
        orm_mode = True
class CouponValidateRequest(BaseModel):
    code: str
    order_value: float
class CouponValidateResponse(BaseModel):
    valid: bool
    discount_value: float
    message: Optional[str]    