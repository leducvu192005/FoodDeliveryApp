from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database import get_db
from models import User
from schemas import RegisterRequest, LoginRequest
from auth import hash_password, verify_password

router = APIRouter(prefix="/auth", tags=["Auth"])

@router.post("/register")
def register(data: RegisterRequest, db: Session = Depends(get_db)):
    if data.role not in ["buyer", "seller", "shipper"]:
        raise HTTPException(status_code=400, detail="Role không hợp lệ")

    if db.query(User).filter(User.email == data.email).first():
        raise HTTPException(status_code=400, detail="Email đã tồn tại")

    user = User(
        full_name=data.full_name,
        email=data.email,
        password_hash=hash_password(data.password.strip()),

        role=data.role
    )

    db.add(user)
    db.commit()

    return {"message": "Đăng ký thành công"}
@router.post("/login")
def login(data: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == data.email.strip()).first()

    if not user or not verify_password(
        data.password.strip(),
        user.password_hash
    ):
        raise HTTPException(status_code=401, detail="Sai email hoặc mật khẩu")

    return {
        "message": "Đăng nhập thành công",
        "user_id": user.id,
        "role": user.role
    }
