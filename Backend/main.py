from fastapi import FastAPI
from database import engine
from models import Base
from routers.auth_router import router as auth_router
from routers.coupons_router import router as coupons_router
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Food Delivery App")

app.include_router(auth_router)
app.include_router(coupons_router)
@app.get("/")
def read_root():
    return {"message": "Welcome to the Food Delivery App Backend!"}
