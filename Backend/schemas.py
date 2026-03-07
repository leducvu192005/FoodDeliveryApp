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
    delivery_address: Optional[str] = None
    delivery_lat: Optional[float] = None
    delivery_lng: Optional[float] = None


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


class ShipperOrderResponse(BaseModel):
    id: int
    customer_name: str
    customer_phone: str
    total_price: float
    delivery_fee: float
    distance_km: float
    pickup_address: str
    delivery_address: str
    pickup_lat: Optional[float] = None
    pickup_lng: Optional[float] = None
    delivery_lat: Optional[float] = None
    delivery_lng: Optional[float] = None
    estimated_delivery_minutes: Optional[int] = None
    status: str
    created_at: Optional[datetime] = None


class ShipperDashboardResponse(BaseModel):
    shipper_name: str
    rating: float
    is_online: bool
    online_minutes_today: int
    today_earnings: float
    completed_orders_today: int
    total_orders: int = 0
    total_distance_today: float
    active_order: Optional[ShipperOrderResponse] = None
    available_orders: list[ShipperOrderResponse]


class ShipperLocationRequest(BaseModel):
    shipper_id: Optional[str] = None
    lat: float
    lng: float


class ShipperOnlineRequest(BaseModel):
    shipper_id: Optional[str] = None
    is_online: bool


class ShipperRadiusRequest(BaseModel):
    shipper_id: Optional[str] = None
    radius_km: int


class ShipperHomeResponse(BaseModel):
    id: int
    name: str
    phone: Optional[str] = None
    avatar: Optional[str] = None
    is_online: bool
    lat: Optional[float] = None
    lng: Optional[float] = None
    last_location_update: Optional[datetime] = None
    accept_radius: int


class ShipperStatusResponse(BaseModel):
    message: str
    is_online: bool


class ShipperLocationUpdateRequest(BaseModel):
    shipper_id: Optional[str] = None
    lat: float
    lng: float


class ShipperLocationResponse(BaseModel):
    message: str
    lat: float
    lng: float
    last_location_update: Optional[datetime] = None


class ShipperRadiusResponse(BaseModel):
    message: str
    accept_radius: int


class ShipperMessageResponse(BaseModel):
    message: str


class ShipperProfileResponse(BaseModel):
    shipper_id: int
    user_id: int
    name: str
    email: str
    phone: str
    address: str = ""
    avatar: Optional[str] = None
    vehicle_type: str
    license_plate: str = ""
    rating: float
    is_online: bool
    current_lat: Optional[float] = None
    current_lng: Optional[float] = None
    last_location_update: Optional[datetime] = None
    accept_radius: int
    completed_orders: int = 0
    completion_rate: float = 0
    online_since: Optional[datetime] = None


class ShipperProfileUpdateRequest(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    lat: Optional[float] = None
    lng: Optional[float] = None


class ShipperEarningsResponse(BaseModel):
    total_earnings: float
    completed_orders: int


class ShipperEarningsSummaryResponse(BaseModel):
    today: float
    week: float
    month: float
    total_earnings: float
    total_orders: int
    average_per_order: float


class ShipperLegacyOrderResponse(BaseModel):
    id: int
    customer_name: str
    customer_phone: str
    restaurant_name: str
    pickup_address: str
    delivery_address: str
    total_price: float
    shipping_fee: float
    status: str
    created_at: Optional[datetime] = None
    delivered_at: Optional[datetime] = None
    distance_km: float = 0
    estimated_delivery_minutes: Optional[int] = None
    pickup_lat: Optional[float] = None
    pickup_lng: Optional[float] = None
    delivery_lat: Optional[float] = None
    delivery_lng: Optional[float] = None


class ShipperCurrentOrderResponse(BaseModel):
    order: Optional[ShipperLegacyOrderResponse] = None


class ShipperOrderItemResponse(BaseModel):
    id: int
    dish_name: str
    quantity: int
    unit_price: float


class ShipperOrderDetailResponse(ShipperLegacyOrderResponse):
    items: list[ShipperOrderItemResponse] = []


class ShipperOrderHistoryResponse(BaseModel):
    orders: list[ShipperLegacyOrderResponse]


class SepayPaymentResponse(BaseModel):
    payment_id: int
    transaction_id: str
    qr_url: str
    bank_code: str
    account_number: str
    account_name: str
    amount: float
    transfer_content: str
    message: str


class SepayStatusResponse(BaseModel):
    status: str
    amount: float
    transaction_id: str
    paid_at: Optional[datetime]
