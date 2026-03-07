from operator import or_

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from auth import create_access_token, hash_password, verify_password
from database import get_db
from models import Shipper, User
from schemas import LoginRequest, RegisterRequest

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/register")
def register(data: RegisterRequest, db: Session = Depends(get_db)):
    phone = (data.sdt or "").strip()

    if data.role not in ["buyer", "seller", "shipper"]:
        raise HTTPException(status_code=400, detail="Role khong hop le")
    if not phone:
        raise HTTPException(status_code=400, detail="So dien thoai khong duoc de trong")

    if db.query(User).filter(User.email == data.email).first():
        raise HTTPException(status_code=400, detail="Email da ton tai")
    if db.query(User).filter(User.sdt == phone).first():
        raise HTTPException(status_code=400, detail="So dien thoai da ton tai")

    user = User(
        full_name=data.full_name,
        email=data.email,
        sdt=phone,
        password_hash=hash_password(data.password.strip()),
        role=data.role,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    if user.role == "shipper":
        existing_shipper = db.query(Shipper).filter(Shipper.user_id == user.id).first()
        if not existing_shipper:
            db.add(
                Shipper(
                    user_id=user.id,
                    full_name=user.full_name,
                    phone=phone,
                    verhice_type="motorbike",
                    is_online=False,
                    rating=5.0,
                )
            )
            db.commit()

    return {"message": "Dang ky thanh cong"}


@router.post("/login")
def login(data: LoginRequest, db: Session = Depends(get_db)):
    user = (
        db.query(User)
        .filter(or_(User.email == data.email, User.sdt == data.email))
        .first()
    )

    if not user or not verify_password(data.password.strip(), user.password_hash):
        raise HTTPException(status_code=401, detail="Sai email, sdt hoac mat khau")

    access_token = create_access_token(
        data={
            "user_id": str(user.id),
            "role": user.role,
        }
    )

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user_id": user.id,
        "role": user.role,
    }
