from fastapi import FastAPI
import os
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
from routers.shipper_router import (
    legacy_router as shipper_legacy_router,
    router as shipper_router,
    ws_router as shipper_ws_router,
)
from setup_shipper_tables import setup_shipper_tables
from setup_user_columns import setup_user_columns
Base.metadata.create_all(bind=engine)
setup_shipper_tables()
setup_user_columns()

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
app.include_router(shipper_legacy_router)
app.include_router(shipper_ws_router)
# 🔥 Payment thêm prefix cho đúng
app.include_router(payment_router, prefix="/api/payment", tags=["Payment"])

@app.get("/")
def read_root():
    return {"message": "Welcome to the Food Delivery App Backend!"}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "main:app",
        host=os.getenv("BACKEND_HOST", "0.0.0.0"),
        port=int(os.getenv("BACKEND_PORT", "8000")),
        reload=os.getenv("BACKEND_RELOAD", "true").lower() == "true",
    )
