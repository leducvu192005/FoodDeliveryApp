from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from database import get_db
from models import CartItem, Order, OrderItem, Payment, User
from schemas import (
    CartCheckoutRequest,
    CartCheckoutResponse,
    CartItemCreate,
    CartItemResponse,
    CartItemUpdate,
)
from dependencies import get_current_user

router = APIRouter(prefix="/cart", tags=["Cart"])


@router.get("/items", response_model=List[CartItemResponse])
def get_cart_items(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    return (
        db.query(CartItem)
        .filter(CartItem.user_id == user.id)
        .all()
    )

@router.post("/add", response_model=list[CartItemResponse])
def add_to_cart(
    item: CartItemCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    cart_item = db.query(CartItem).filter(
        CartItem.user_id == user.id,
        CartItem.dish_id == item.dish_id
    ).first()

    if cart_item:
        cart_item.quantity += item.quantity
    else:
        cart_item = CartItem(
            user_id=user.id,
            dish_id=item.dish_id,
            quantity=item.quantity
        )
        db.add(cart_item)

    db.commit()
    db.refresh(cart_item)

    return (
        db.query(CartItem)
        .filter(CartItem.user_id == user.id)
        .all()
    )

@router.put("/update", response_model=List[CartItemResponse])
def update_cart_quantity(
    item: CartItemUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    cart_item = db.query(CartItem).filter(
        CartItem.user_id == user.id,
        CartItem.dish_id == item.dish_id
    ).first()

    if not cart_item:
        raise HTTPException(status_code=404, detail="Món ăn không có trong giỏ")

    if item.quantity <= 0:
        db.delete(cart_item)
    else:
        cart_item.quantity = item.quantity

    db.commit()

    # ✅ TRẢ VỀ CartItem ORM
    return (
        db.query(CartItem)
        .filter(CartItem.user_id == user.id)
        .all()
    )
@router.delete("/remove", response_model=List[CartItemResponse])
def remove_from_cart(
    dish_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user)
):
    cart_item = db.query(CartItem).filter(
        CartItem.user_id == user.id,
        CartItem.dish_id == dish_id
    ).first()

    if not cart_item:
        raise HTTPException(status_code=404, detail="Không tìm thấy món cần xóa")

    db.delete(cart_item)
    db.commit()

    return (
        db.query(CartItem)
        .filter(CartItem.user_id == user.id)
        .all()
    )

@router.post("/checkout")
def checkout_cart(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    cart_items = (
        db.query(CartItem)
        .filter(CartItem.user_id == user.id)
        .all()
    )

    if not cart_items:
        raise HTTPException(status_code=400, detail="Gio hang trong")

    total_amount = sum(
        (item.dish.price or 0) * item.quantity
        for item in cart_items
    )

    # 1️⃣ Tạo Order
    order = Order(
        user_id=user.id,
        total_price=total_amount,
        status="pending",
        payment_method="stripe",
    )
    db.add(order)
    db.flush()

    # 2️⃣ Tạo OrderItem
    for item in cart_items:
        order_item = OrderItem(
            order_id=order.id,
            dish_id=item.dish_id,
            dish_name=item.dish.name,
            dish_image=item.dish.img,
            dish_price=item.dish.price,
            quantity=item.quantity,
        )
        db.add(order_item)

    # 3️⃣ Xóa giỏ hàng
    for item in cart_items:
        db.delete(item)

    db.commit()

    # 4️⃣ Trả về đúng cho Flutter
    return {
        "order_id": order.id,
        "total_price": total_amount,
    }

