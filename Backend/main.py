from fastapi import FastAPI
from database import engine
from models import Base
from routers.auth_router import router as auth_router
from routers.coupons_router import router as coupons_router
from routers.products_router import router as products_router
from routers.category import  router as category_router
from routers.dish import router as dish_router
from routers.topping import router as topping_router
from routers.profile import router as profile_router 
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Food Delivery App")
app.include_router(category_router)
app.include_router(dish_router)
app.include_router(topping_router)
app.include_router(auth_router)
app.include_router(products_router)
app.include_router(coupons_router)
app.include_router(profile_router)
@app.get("/")
def read_root():
    return {"message": "Welcome to the Food Delivery App Backend!"}
