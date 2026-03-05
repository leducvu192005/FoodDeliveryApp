from fastapi import FastAPI
from database import engine
from models import Base

from routers.auth_router import router as auth_router
from routers.discount_codes_router import router as discount_codes_router
from routers.products_router import router as products_router
from routers.category import router as category_router
from routers.dish import router as dish_router
from routers.topping import router as topping_router
from routers.profile import router as profile_router
from routers.cartItems_router import router as cart_router
from routers.payment_router import router as payment_router
from routers.shipper_router import router as shipper_router
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Food Delivery App")

app.include_router(auth_router)
app.include_router(products_router)
app.include_router(discount_codes_router)
app.include_router(category_router)
app.include_router(dish_router)
app.include_router(topping_router)
app.include_router(profile_router)
app.include_router(cart_router)
app.include_router(shipper_router)
# 🔥 Payment thêm prefix cho đúng
app.include_router(payment_router, prefix="/api/payment", tags=["Payment"])

@app.get("/")
def read_root():
    return {"message": "Welcome to the Food Delivery App Backend!"}
