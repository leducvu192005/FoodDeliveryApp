from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
import models
from dependencies import get_current_user, require_role

router = APIRouter(prefix="/shipper", tags=["Shipper"])


@router.patch("/toggle-online")
def toggle_online(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role("shipper"))
):
    shipper = db.query(models.User).filter(models.User.id == current_user.id).first()
    if not shipper:
        raise HTTPException(status_code=404, detail="Shipper không tồn tại")
    shipper.is_online = not shipper.is_online
    db.commit()
    db.refresh(shipper)
    return {
        "is_online": shipper.is_online
    }


@router.get("/orders")
def get_available_orders(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role("shipper"))
):
    """Lấy danh sách đơn hàng đang chờ shipper nhận (status='shipper')"""
    orders = (
        db.query(models.Order)
        .filter(models.Order.status == "shipper")
        .order_by(models.Order.id.desc())
        .all()
    )

    result = []
    for order in orders:
        order_items = (
            db.query(models.OrderItem)
            .filter(models.OrderItem.order_id == order.id)
            .all()
        )
        result.append({
            "id": order.id,
            "user_id": order.user_id,
            "total_price": order.total_price,
            "status": order.status,
            "created_at": order.created_at,
            "items": [
                {
                    "dish_name": item.dish_name,
                    "dish_price": item.dish_price,
                    "quantity": item.quantity,
                }
                for item in order_items
            ],
        })
    return result


@router.patch("/accept/{order_id}")
def accept_order(
    order_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role("shipper"))
):
    """Shipper nhận đơn → status chuyển sang 'seller' (đang lấy hàng)"""
    order = db.query(models.Order).filter(models.Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Không tìm thấy đơn hàng")
    if order.status != "shipper":
        raise HTTPException(status_code=400, detail=f"Đơn hàng không ở trạng thái chờ shipper (hiện tại: {order.status})")

    order.status = "seller"
    db.commit()
    return {"message": "Đã nhận đơn hàng", "order_id": order.id, "status": order.status}


@router.patch("/complete/{order_id}")
def complete_order(
    order_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role("shipper"))
):
    """Shipper giao hàng xong → status chuyển sang 'done'"""
    order = db.query(models.Order).filter(models.Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Không tìm thấy đơn hàng")
    if order.status != "seller":
        raise HTTPException(status_code=400, detail=f"Đơn hàng chưa ở trạng thái đang giao (hiện tại: {order.status})")

    order.status = "done"
    db.commit()
    return {"message": "Đã hoàn thành đơn hàng", "order_id": order.id, "status": order.status}