from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime
from typing import Optional

from database import get_db
from models import DiscountCode, User
from schemas import DiscountCodeCreate, DiscountCodeResponse, DiscountCodeValidateRequest, DiscountCodeValidateResponse, DiscountCodeUpdate
from dependencies import get_current_user, require_role

router = APIRouter(prefix="/discount-codes", tags=["Discount Codes"])

@router.post("/", response_model=DiscountCodeResponse)
def create_discount_code(
    data: DiscountCodeCreate,
    db: Session = Depends(get_db),
    user: User = Depends(require_role("seller")),
):
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
        seller_id=user.id,
        create_by=user.id,
    )
    db.add(discount_code)
    db.commit()
    db.refresh(discount_code)
    return discount_code

@router.get("/", response_model=list[DiscountCodeResponse])
def list_all_discount_codes(
    db: Session = Depends(get_db),
    user: User = Depends(require_role("seller")),
):
    """Lấy discount code của seller hiện tại"""
    return db.query(DiscountCode).filter(DiscountCode.seller_id == user.id).all()

@router.get("/active", response_model=list[DiscountCodeResponse])
def list_active_discount_codes(
    seller_id: Optional[int] = None,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    now = datetime.now()
    q = db.query(DiscountCode).filter(DiscountCode.active == True)
    q = q.filter((DiscountCode.start_at == None) | (DiscountCode.start_at <= now))
    q = q.filter((DiscountCode.end_at == None) | (DiscountCode.end_at >= now))
    if seller_id is not None:
        q = q.filter(DiscountCode.seller_id == seller_id)
    # Chỉ hiện mã dành cho tất cả (user_id=null) hoặc dành riêng cho user hiện tại
    q = q.filter((DiscountCode.user_id == None) | (DiscountCode.user_id == user.id))
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
def validate_discount_code(
    data: DiscountCodeValidateRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    discount_code = db.query(DiscountCode).filter(
        DiscountCode.code == data.code,
        DiscountCode.active == True,
    ).first()
    if not discount_code:
        return {"valid": False, "discount_amount": 0.0, "final_total": data.cart_total, "message": "Ma giam gia khong ton tai"}

    # Kiểm tra seller_id: mã chỉ áp dụng cho món của seller tạo mã
    if data.seller_id is not None and discount_code.seller_id != data.seller_id:
        return {"valid": False, "discount_amount": 0.0, "final_total": data.cart_total, "message": "Ma giam gia khong ap dung cho cua hang nay"}

    # Kiểm tra user_id: nếu mã gắn user cụ thể thì chỉ user đó dùng được
    if discount_code.user_id is not None and discount_code.user_id != user.id:
        return {"valid": False, "discount_amount": 0.0, "final_total": data.cart_total, "message": "Ma giam gia khong danh cho ban"}

    now = datetime.now()
    if (discount_code.start_at and discount_code.start_at > now) or (discount_code.end_at and discount_code.end_at < now):
        return {"valid": False, "discount_amount": 0.0, "final_total": data.cart_total, "message": "Ma giam gia khong con hieu luc"}
    if data.cart_total < float(discount_code.min_order_value or 0):
        return {"valid": False, "discount_amount": 0.0, "final_total": data.cart_total, "message": f"Don hang toi thieu {int(discount_code.min_order_value or 0)}d"}
    if discount_code.discount_type == "percent":
        discount = float(data.cart_total) * (float(discount_code.discount_value) / 100.0)
    else:
        discount = float(discount_code.discount_value)
    final = max(0.0, float(data.cart_total) - discount)
    return {"valid": True, "discount_amount": round(discount, 2), "final_total": round(final, 2), "message": "Ap dung thanh cong"}