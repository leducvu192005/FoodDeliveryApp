from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime
from typing import Optional

from database import get_db
from models import DiscountCode
from schemas import DiscountCodeCreate, DiscountCodeResponse, DiscountCodeValidateRequest, DiscountCodeValidateResponse, DiscountCodeUpdate

router = APIRouter(prefix="/discount-codes", tags=["Discount Codes"])

@router.post("/", response_model=DiscountCodeResponse)
def create_discount_code(data: DiscountCodeCreate, db: Session = Depends(get_db)):
    if db.query(DiscountCode).filter(DiscountCode.code == data.code).first():
        raise HTTPException(status_code=400, detail="Discount code already exists")
    discount_code = DiscountCode(
        code=data.code,
        title=data.title,
        description=data.description,
        discount_type=data.discount_type,
        discount_value=data.discount_value,
        min_order_value=data.min_order_value,
        start_at=data.start_at,
        end_at=data.end_at,
        active=True,
        user_id=data.user_id,
        create_by=1  # TODO: Get from JWT token
    )
    db.add(discount_code)
    db.commit()
    db.refresh(discount_code)
    return discount_code

@router.get("/", response_model=list[DiscountCodeResponse])
def list_all_discount_codes(db: Session = Depends(get_db)):
    """Lấy tất cả discount code (cho seller quản lý)"""
    return db.query(DiscountCode).all()

@router.get("/active", response_model=list[DiscountCodeResponse])
def list_active_discount_codes(db: Session = Depends(get_db)):
    now = datetime.utcnow()
    q = db.query(DiscountCode).filter(DiscountCode.active == True)
    q = q.filter((DiscountCode.start_at == None) | (DiscountCode.start_at <= now))
    q = q.filter((DiscountCode.end_at == None) | (DiscountCode.end_at >= now))
    return q.all()

@router.get("/{discount_code_id}", response_model=DiscountCodeResponse)
def get_discount_code(discount_code_id: int, db: Session = Depends(get_db)):
    discount_code = db.query(DiscountCode).filter(DiscountCode.id == discount_code_id).first()
    if not discount_code:
        raise HTTPException(status_code=404, detail="Discount code not found")
    return discount_code

@router.put("/{discount_code_id}", response_model=DiscountCodeResponse)
def update_discount_code(discount_code_id: int, data: DiscountCodeUpdate, db: Session = Depends(get_db)):
    discount_code = db.query(DiscountCode).filter(DiscountCode.id == discount_code_id).first()
    if not discount_code:
        raise HTTPException(status_code=404, detail="Discount code not found")
    
    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(discount_code, key, value)
    
    db.commit()
    db.refresh(discount_code)
    return discount_code

@router.delete("/{discount_code_id}")
def delete_discount_code(discount_code_id: int, db: Session = Depends(get_db)):
    discount_code = db.query(DiscountCode).filter(DiscountCode.id == discount_code_id).first()
    if not discount_code:
        raise HTTPException(status_code=404, detail="Discount code not found")
    
    db.delete(discount_code)
    db.commit()
    return {"success": True, "message": "Discount code deleted successfully"}

@router.post("/validate", response_model=DiscountCodeValidateResponse)
def validate_discount_code(data: DiscountCodeValidateRequest, db: Session = Depends(get_db)):
    discount_code = db.query(DiscountCode).filter(DiscountCode.code == data.code, DiscountCode.active == True).first()
    if not discount_code:
        return {"valid": False, "discount_amount": 0.0, "final_total": data.cart_total, "message": "Mã giảm giá không tồn tại"}
    now = datetime.utcnow()
    if (discount_code.start_at and discount_code.start_at > now) or (discount_code.end_at and discount_code.end_at < now):
        return {"valid": False, "discount_amount": 0.0, "final_total": data.cart_total, "message": "Mã giảm giá không còn hiệu lực"}
    if data.cart_total < float(discount_code.min_order_value):
        return {"valid": False, "discount_amount": 0.0, "final_total": data.cart_total, "message": "Giá trị đơn nhỏ hơn yêu cầu"}
    if discount_code.discount_type == "percent":
        discount = float(data.cart_total) * (float(discount_code.discount_value) / 100.0)
    else:
        discount = float(discount_code.discount_value)
    final = max(0.0, float(data.cart_total) - discount)
    return {"valid": True, "discount_amount": round(discount,2), "final_total": round(final,2), "message": "Áp dụng thành công"}