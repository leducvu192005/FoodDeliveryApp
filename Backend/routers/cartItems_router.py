import os
from typing import List

from fastapi import APIRouter, Depends, HTTPException
import stripe
from sqlalchemy.orm import Session

from database import get_db
from dependencies import get_current_user, require_role
from models import CartItem, Order, OrderItem, Payment, PendingStripeCheckout, Profile, User
from schemas import (
    CartCheckoutRequest,
    CartItemCreate,
    CartItemResponse,
    CartItemUpdate,
)

router = APIRouter(prefix="/cart", tags=["Cart"])

stripe.api_key = os.getenv("STRIPE_API_KEY", "test")


@router.get("/orders")
def get_user_orders(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    orders = (
        db.query(Order)
        .filter(Order.user_id == user.id)
        .order_by(Order.id.desc())
        .all()
    )

    result = []
    for order in orders:
        order_items = (
            db.query(OrderItem)
            .filter(OrderItem.order_id == order.id)
            .all()
        )
        payment = (
            db.query(Payment)
            .filter(Payment.order_id == order.id)
            .order_by(Payment.id.desc())
            .first()
        )

        result.append({
            "id": order.id,
            "status": order.status,
            "payment_method": order.payment_method,
            "total_price": order.total_price,
            "delivery_address": order.delivery_address,
            "created_at": order.created_at,
            "payment_status": payment.status if payment else "pending",
            "items": [
                {
                    "id": item.id,
                    "dish_id": item.dish_id,
                    "dish_name": item.dish_name,
                    "dish_image": item.dish_image,
                    "dish_price": item.dish_price,
                    "quantity": item.quantity,
                }
                for item in order_items
            ],
        })

    return result


@router.get("/seller-orders")
def get_seller_orders(
    db: Session = Depends(get_db),
    user: User = Depends(require_role("seller")),
):
    orders = (
        db.query(Order)
        .filter(
            Order.seller_id == user.id,
            Order.status.in_(["seller", "done"]),
        )
        .order_by(Order.id.desc())
        .all()
    )

    result = []
    for order in orders:
        order_items = (
            db.query(OrderItem)
            .filter(OrderItem.order_id == order.id)
            .all()
        )
        result.append({
            "id": order.id,
            "user_id": order.user_id,
            "status": order.status,
            "total_price": order.total_price,
            "created_at": order.created_at,
            "items": [
                {
                    "id": item.id,
                    "dish_name": item.dish_name,
                    "dish_image": item.dish_image,
                    "dish_price": item.dish_price,
                    "quantity": item.quantity,
                }
                for item in order_items
            ],
        })
    return result


@router.get("/items", response_model=List[CartItemResponse])
def get_cart_items(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
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
        CartItem.dish_id == item.dish_id,
    ).first()

    if cart_item:
        cart_item.quantity += item.quantity
    else:
        cart_item = CartItem(
            user_id=user.id,
            dish_id=item.dish_id,
            quantity=item.quantity,
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
    user: User = Depends(get_current_user),
):
    cart_item = db.query(CartItem).filter(
        CartItem.user_id == user.id,
        CartItem.dish_id == item.dish_id,
    ).first()

    if not cart_item:
        raise HTTPException(status_code=404, detail="Mon an khong co trong gio")

    if item.quantity <= 0:
        db.delete(cart_item)
    else:
        cart_item.quantity = item.quantity

    db.commit()

    return (
        db.query(CartItem)
        .filter(CartItem.user_id == user.id)
        .all()
    )


@router.delete("/remove", response_model=List[CartItemResponse])
def remove_from_cart(
    dish_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    cart_item = db.query(CartItem).filter(
        CartItem.user_id == user.id,
        CartItem.dish_id == dish_id,
    ).first()

    if not cart_item:
        raise HTTPException(status_code=404, detail="Khong tim thay mon can xoa")

    db.delete(cart_item)
    db.commit()

    return (
        db.query(CartItem)
        .filter(CartItem.user_id == user.id)
        .all()
    )


@router.post("/checkout")
def checkout_cart(
    request: CartCheckoutRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    payment_method = (request.method or "").strip().lower()
    if payment_method not in {"cod", "stripe"}:
        raise HTTPException(status_code=400, detail="Phuong thuc thanh toan khong hop le")

    cart_items = (
        db.query(CartItem)
        .filter(CartItem.user_id == user.id)
        .all()
    )

    if not cart_items:
        raise HTTPException(status_code=400, detail="Gio hang trong")

    total_amount = sum((item.dish.price or 0) * item.quantity for item in cart_items)

    buyer_profile = (
        db.query(Profile)
        .filter(Profile.user_id == user.id)
        .order_by(Profile.id.desc())
        .first()
    )
    request_address = (request.delivery_address or "").strip()
    profile_address = buyer_profile.live.strip() if buyer_profile and buyer_profile.live else ""
    delivery_address = request_address or profile_address or "Customer address pending"

    seller_id = cart_items[0].dish.seller_id if cart_items else None
    seller_profile = None
    if seller_id is not None:
        seller_profile = (
            db.query(Profile)
            .filter(Profile.user_id == seller_id)
            .order_by(Profile.id.desc())
            .first()
        )
    pickup_address = (
        seller_profile.live if seller_profile and seller_profile.live else "Restaurant address pending"
    )
    delivery_fee = max(float(total_amount) * 0.1, 12000.0)
    estimated_delivery_minutes = 25

    if payment_method == "stripe":
        cart_snapshot = [
            {
                "dish_id": item.dish_id,
                "dish_name": item.dish.name,
                "dish_image": item.dish.img,
                "dish_price": item.dish.price,
                "quantity": item.quantity,
            }
            for item in cart_items
        ]

        try:
            pending_checkout = PendingStripeCheckout(
                user_id=user.id,
                total_price=total_amount,
                delivery_fee=delivery_fee,
                distance_km=2.5,
                pickup_address=pickup_address,
                delivery_address=delivery_address,
                estimated_delivery_minutes=estimated_delivery_minutes,
                status="pending",
                cart_snapshot=cart_snapshot,
            )
            db.add(pending_checkout)
            db.flush()

            intent = stripe.PaymentIntent.create(
                amount=int(total_amount * 100),
                currency="usd",
                metadata={
                    "pending_checkout_id": str(pending_checkout.id),
                    "user_id": str(user.id),
                },
            )

            pending_checkout.payment_intent_id = intent["id"]
            db.commit()

            return {
                "checkout_id": pending_checkout.id,
                "client_secret": intent["client_secret"],
                "total_price": total_amount,
                "delivery_address": delivery_address,
                "payment_method": payment_method,
                "payment_status": "pending",
            }
        except stripe.error.StripeError as exc:
            db.rollback()
            raise HTTPException(
                status_code=400,
                detail=f"Khong tao duoc giao dich Stripe: {str(exc)}",
            ) from exc
        except Exception as exc:
            db.rollback()
            raise HTTPException(
                status_code=500,
                detail="Khong tao duoc giao dich Stripe",
            ) from exc

    order = Order(
        user_id=user.id,
        seller_id=seller_id,
        total_price=total_amount,
        delivery_fee=delivery_fee,
        distance_km=2.5,
        pickup_address=pickup_address,
        delivery_address=delivery_address,
        estimated_delivery_minutes=estimated_delivery_minutes,
        status="pending",
        payment_method="cod",
    )
    db.add(order)
    db.flush()

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

    db.add(
        Payment(
            order_id=order.id,
            amount=total_amount,
            method="cod",
            status="pending",
        )
    )
    for item in cart_items:
        db.delete(item)

    db.commit()

    return {
        "order_id": order.id,
        "total_amount": total_amount,
        "total_price": total_amount,
        "delivery_address": delivery_address,
        "payment_method": "cod",
        "payment_status": "pending",
        "message": "Order created successfully",
    }
