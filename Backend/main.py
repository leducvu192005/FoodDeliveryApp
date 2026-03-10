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
from routers.favorites_router import router as favorites_router
from routers.sepay_router import router as sepay_router
from routers.shipper_router import (
    legacy_router as shipper_legacy_router,
    router as shipper_router,
    ws_router as shipper_ws_router,
)
from routers.form_seller_router import router as form_seller_router
from routers.form_shipper_router import router as form_shipper_router
from routers.admin_router import router as admin_router
from routers.seller_router import router as seller_router
from routers.display_router import router as display_router
from setup_shipper_tables import setup_shipper_tables
from setup_favorites_table import setup_favorites_table
from setup_user_columns import setup_user_columns
from setup_discount_columns import setup_discount_columns
from setup_sellers_table import setup_sellers_table
Base.metadata.create_all(bind=engine)
setup_shipper_tables()
setup_favorites_table()
setup_user_columns()
setup_discount_columns()
setup_sellers_table()

app = FastAPI(title="Food Delivery App")

app.include_router(auth_router)
app.include_router(products_router)
app.include_router(discount_codes_router)
app.include_router(category_router)
app.include_router(dish_router)
app.include_router(topping_router)
app.include_router(profile_router)
app.include_router(cart_router)
app.include_router(favorites_router)
app.include_router(shipper_router)
app.include_router(shipper_legacy_router)
app.include_router(shipper_ws_router)
app.include_router(sepay_router, prefix="/api/sepay", tags=["Sepay Payment"])
app.include_router(form_seller_router)
app.include_router(form_shipper_router)
app.include_router(admin_router)
app.include_router(seller_router)
app.include_router(display_router)

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
