from fastapi import FastAPI
from database import engine
from models import Base
from routers.auth_router import router as auth_router

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Food Delivery App")

app.include_router(auth_router)
