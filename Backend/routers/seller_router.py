from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import Optional

from database import get_db
from models import Order, Seller, User, HistoryPriceSeller
from dependencies import get_current_user, require_role

router = APIRouter(prefix="/seller", tags=["Seller"])


# ==================== Profile seller ====================

@router.get("/profile")
def get_seller_profile(
    db: Session = Depends(get_db),
    user: User = Depends(require_role("seller")),
):
    seller = db.query(Seller).filter(Seller.user_id == user.id).first()
    if not seller:
        raise HTTPException(status_code=404, detail="Chua co thong tin seller")
    return {
        "id": seller.id,
        "user_id": seller.user_id,
        "name": seller.name,
        "status": seller.status,
        "address": seller.address,
        "phone": seller.phone,
        "email": seller.email,
        "cccd": seller.cccd,
        "lat": seller.lat,
        "lng": seller.lng,
        "price": seller.price,
        "created_at": str(seller.created_at) if seller.created_at else None,
    }


class SellerProfileUpdate(BaseModel):
    name: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None


@router.put("/profile")
def update_seller_profile(
    body: SellerProfileUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(require_role("seller")),
):
    seller = db.query(Seller).filter(Seller.user_id == user.id).first()
    if not seller:
        raise HTTPException(status_code=404, detail="Chua co thong tin seller")
    if body.name is not None:
        seller.name = body.name
    if body.address is not None:
        seller.address = body.address
    if body.phone is not None:
        seller.phone = body.phone
    db.commit()
    return {
        "id": seller.id,
        "name": seller.name,
        "address": seller.address,
        "phone": seller.phone,
    }


# ==================== Trạng thái hoạt động quán ====================

class SellerStatusUpdate(BaseModel):
    status: str  # "on" hoặc "off"


@router.get("/status")
def get_seller_status(
    db: Session = Depends(get_db),
    user: User = Depends(require_role("seller")),
):
    seller = db.query(Seller).filter(Seller.user_id == user.id).first()
    if not seller:
        raise HTTPException(status_code=404, detail="Chua co thong tin seller")
    return {"status": seller.status, "name": seller.name}


@router.patch("/status")
def toggle_seller_status(
    body: SellerStatusUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(require_role("seller")),
):
    new_status = body.status.strip().lower()
    if new_status not in {"on", "off"}:
        raise HTTPException(status_code=400, detail="Status phai la 'on' hoac 'off'")

    seller = db.query(Seller).filter(Seller.user_id == user.id).first()
    if not seller:
        raise HTTPException(status_code=404, detail="Chua co thong tin seller")

    seller.status = new_status
    db.commit()
    return {"status": seller.status}


# ==================== Doanh thu ====================

@router.get("/revenue")
def get_seller_revenue(
    db: Session = Depends(get_db),
    user: User = Depends(require_role("seller")),
):
    seller = db.query(Seller).filter(Seller.user_id == user.id).first()
    if not seller:
        raise HTTPException(status_code=404, detail="Chua co thong tin seller")

    # Đếm đơn delivered hôm nay
    from datetime import datetime
    today_start = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)

    today_orders = (
        db.query(func.count(Order.id))
        .filter(
            Order.seller_id == user.id,
            Order.status == "delivered",
            Order.created_at >= today_start,
        )
        .scalar() or 0
    )

    today_revenue = (
        db.query(func.coalesce(func.sum(Order.total_price), 0))
        .filter(
            Order.seller_id == user.id,
            Order.status == "delivered",
            Order.created_at >= today_start,
        )
        .scalar() or 0
    )

    return {
        "total_revenue": seller.price,
        "today_revenue": float(today_revenue) * 0.8,
        "today_orders": today_orders,
    }


# ==================== Seller đánh dấu đã làm xong ====================

@router.patch("/orders/{order_id}/done")
def seller_mark_done(
    order_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_role("seller")),
):
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Khong tim thay don hang")
    if order.seller_id != user.id:
        raise HTTPException(status_code=403, detail="Khong phai don cua ban")
    if order.status not in ("pending", "confirmed"):
        raise HTTPException(
            status_code=400,
            detail=f"Khong the danh dau xong voi trang thai '{order.status}'",
        )

    order.status = "confirmed"
    db.commit()
    return {"id": order.id, "status": order.status}


# ==================== Ví seller ====================

@router.get("/wallet")
def get_seller_wallet(
    db: Session = Depends(get_db),
    user: User = Depends(require_role("seller")),
):
    seller = db.query(Seller).filter(Seller.user_id == user.id).first()
    if not seller:
        raise HTTPException(status_code=404, detail="Chua co thong tin seller")
    return {"balance": seller.price or 0}


class WithdrawRequest(BaseModel):
    amount: float
    note: Optional[str] = None


@router.post("/wallet/withdraw")
def withdraw_wallet(
    body: WithdrawRequest,
    db: Session = Depends(get_db),
    user: User = Depends(require_role("seller")),
):
    if body.amount <= 0:
        raise HTTPException(status_code=400, detail="So tien rut phai lon hon 0")

    seller = db.query(Seller).filter(Seller.user_id == user.id).first()
    if not seller:
        raise HTTPException(status_code=404, detail="Chua co thong tin seller")

    current_balance = seller.price or 0
    if body.amount > current_balance:
        raise HTTPException(status_code=400, detail="So du khong du")

    balance_after = current_balance - body.amount

    history = HistoryPriceSeller(
        seller_id=seller.id,
        amount=body.amount,
        balance_before=current_balance,
        balance_after=balance_after,
        note=body.note,
        status="completed",
    )
    seller.price = balance_after
    db.add(history)
    db.commit()

    return {
        "balance": balance_after,
        "withdrawn": body.amount,
    }


@router.get("/wallet/history")
def get_wallet_history(
    db: Session = Depends(get_db),
    user: User = Depends(require_role("seller")),
):
    seller = db.query(Seller).filter(Seller.user_id == user.id).first()
    if not seller:
        raise HTTPException(status_code=404, detail="Chua co thong tin seller")

    records = (
        db.query(HistoryPriceSeller)
        .filter(HistoryPriceSeller.seller_id == seller.id)
        .order_by(HistoryPriceSeller.created_at.desc())
        .limit(50)
        .all()
    )

    return [
        {
            "id": r.id,
            "amount": r.amount,
            "balance_before": r.balance_before,
            "balance_after": r.balance_after,
            "note": r.note,
            "status": r.status,
            "created_at": str(r.created_at) if r.created_at else None,
        }
        for r in records
    ]
