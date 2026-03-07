from operator import or_
import random
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from auth import create_access_token, hash_password, verify_password
from database import get_db
from email_utils import send_otp_email
from models import PasswordReset, Shipper, User
from schemas import ForgotPasswordRequest, LoginRequest, RegisterRequest, ResetPasswordRequest

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/register")
def register(data: RegisterRequest, db: Session = Depends(get_db)):
    phone = (data.sdt or "").strip()

    if data.role not in ["buyer", "seller", "shipper"]:
        raise HTTPException(status_code=400, detail="Role khong hop le")
    if not phone:
        raise HTTPException(status_code=400, detail="So dien thoai khong duoc de trong")

    # Validate extra fields based on role
    if data.role == "shipper":
        if not data.cccd or not data.vehicle_registration or not data.license:
            raise HTTPException(status_code=400, detail="Shipper can nhap CCCD, dang ky xe va so bang lai")
    if data.role == "seller":
        if not data.cccd or not data.name_shop or not data.address_shop:
            raise HTTPException(status_code=400, detail="Seller can nhap CCCD, ten quan va dia chi quan")

    if db.query(User).filter(User.email == data.email).first():
        raise HTTPException(status_code=400, detail="Email da ton tai")
    if db.query(User).filter(User.sdt == phone).first():
        raise HTTPException(status_code=400, detail="So dien thoai da ton tai")

    # buyer gets role immediately, seller/shipper get "pending"
    actual_role = data.role if data.role == "buyer" else "pending"
    actual_status = "pending" if data.role != "buyer" else None

    user = User(
        full_name=data.full_name,
        email=data.email,
        sdt=phone,
        password_hash=hash_password(data.password.strip()),
        role=actual_role,
        status=actual_status,
        cccd=int(data.cccd) if data.cccd else None,
        vehicle_registration=int(data.vehicle_registration) if data.vehicle_registration else None,
        license=int(data.license) if data.license else None,
        name_shop=data.name_shop,
        address_shop=data.address_shop,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    if data.role == "shipper":
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


@router.post("/forgot-password")
def forgot_password(data: ForgotPasswordRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == data.email).first()
    if not user:
        raise HTTPException(status_code=404, detail="Email khong ton tai")

    otp = str(random.randint(100000, 999999))
    expires_at = datetime.utcnow() + timedelta(minutes=10)

    reset = PasswordReset(email=data.email, otp=otp, expires_at=expires_at)
    db.add(reset)
    db.commit()

    try:
        send_otp_email(data.email, otp)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Khong gui duoc email: {e}")

    return {"message": "OTP da duoc gui den email cua ban"}


@router.post("/reset-password")
def reset_password(data: ResetPasswordRequest, db: Session = Depends(get_db)):
    reset = (
        db.query(PasswordReset)
        .filter(
            PasswordReset.email == data.email,
            PasswordReset.otp == data.otp,
            PasswordReset.used == False,
            PasswordReset.expires_at > datetime.utcnow(),
        )
        .order_by(PasswordReset.id.desc())
        .first()
    )

    if not reset:
        raise HTTPException(status_code=400, detail="OTP khong hop le hoac da het han")

    user = db.query(User).filter(User.email == data.email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User khong ton tai")

    user.password_hash = hash_password(data.new_password.strip())
    reset.used = True
    db.commit()

    return {"message": "Dat lai mat khau thanh cong"}
