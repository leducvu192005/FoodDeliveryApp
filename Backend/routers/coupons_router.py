from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime

from database import get_db
from models import Coupon
from schemas import CouponCreate, CouponResponse, CouponValidateRequest, CouponValidateResponse

router = APIRouter(prefix="/coupons", tags=["Coupons"])

@router.post("/", response_model=CouponResponse)
def create_coupon(data: CouponCreate, db: Session = Depends(get_db)):
    if db.query(Coupon).filter(Coupon.code == data.code).first():
        raise HTTPException(status_code=400, detail="Coupon code already exists")
    coupon = Coupon(
        code=data.code,
        title=data.title,
        description=data.description,
        discount_type=data.discount_type,
        discount_value=data.discount_value,
        min_order_value=data.min_order_value,
        start_at=data.start_at,
        end_at=data.end_at,
        active=True
    )
    db.add(coupon)
    db.commit()
    db.refresh(coupon)
    return coupon

@router.get("/active", response_model=list[CouponResponse])
def list_active_coupons(db: Session = Depends(get_db)):
    now = datetime.utcnow()
    q = db.query(Coupon).filter(Coupon.active == True)
    q = q.filter((Coupon.start_at == None) | (Coupon.start_at <= now))
    q = q.filter((Coupon.end_at == None) | (Coupon.end_at >= now))
    return q.all()

@router.post("/validate", response_model=CouponValidateResponse)
def validate_coupon(data: CouponValidateRequest, db: Session = Depends(get_db)):
    coupon = db.query(Coupon).filter(Coupon.code == data.code, Coupon.active == True).first()
    if not coupon:
        return {"valid": False, "discount_amount": 0.0, "final_total": data.cart_total, "message": "Coupon không tồn tại"}
    now = datetime.utcnow()
    if (coupon.start_at and coupon.start_at > now) or (coupon.end_at and coupon.end_at < now):
        return {"valid": False, "discount_amount": 0.0, "final_total": data.cart_total, "message": "Coupon không còn hiệu lực"}
    if data.cart_total < float(coupon.min_order_value):
        return {"valid": False, "discount_amount": 0.0, "final_total": data.cart_total, "message": "Giá trị đơn nhỏ hơn yêu cầu"}
    if coupon.discount_type == "percent":
        discount = float(data.cart_total) * (float(coupon.discount_value) / 100.0)
    else:
        discount = float(coupon.discount_value)
    final = max(0.0, float(data.cart_total) - discount)
    return {"valid": True, "discount_amount": round(discount,2), "final_total": round(final,2), "message": "Áp dụng thành công"}