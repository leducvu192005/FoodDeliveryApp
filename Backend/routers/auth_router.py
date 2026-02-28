from operator import or_

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database import get_db
from models import User
from schemas import RegisterRequest, LoginRequest
from auth import hash_password, verify_password
from auth import create_access_token
from datetime import timedelta
router = APIRouter(prefix="/auth", tags=["Auth"])

@router.post("/register")
def register(data: RegisterRequest, db: Session = Depends(get_db)):
    if data.role not in ["buyer", "seller", "shipper"]:
        raise HTTPException(status_code=400, detail="Role không hợp lệ")

    if db.query(User).filter(User.email == data.email).first():
        raise HTTPException(status_code=400, detail="Email đã tồn tại")
    if db.query(User).filter(User.sdt == data.sdt).first():
        raise HTTPException(status_code=400, detail="Số điện thoại đã tồn tại")
    user = User(
        full_name=data.full_name,
        email=data.email,
        sdt =data.sdt,
        password_hash=hash_password(data.password.strip()),

        role=data.role
    )

    db.add(user)
    db.commit()

    return {"message": "Đăng ký thành công"}
@router.post("/login")
def login(data: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(or_(User.email == data.email, User.sdt == data.email)).first()

    if not user or not verify_password(
        data.password.strip(),
        user.password_hash
    ):
        raise HTTPException(status_code=401, detail="Sai email, sdt hoặc mật khẩu")

    access_token = create_access_token(
        data={
            "user_id": str(user.id),
            "role": user.role
        }
    )

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user_id": user.id,
        "role": user.role
    }