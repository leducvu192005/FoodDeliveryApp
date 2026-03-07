import os
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
import stripe

import models
from database import get_db
from dependencies import get_current_user
from models import CartItem, Order, OrderItem, Payment, PendingStripeCheckout, User
from schemas import PaymentCreateRequest, PaymentResponse

router = APIRouter()

# 🔐 Stripe Keys
stripe.api_key = os.getenv("STRIPE_API_KEY", "test")
endpoint_secret = os.getenv("STRIPE_ENDPOINT_SECRET", "test")


def _clear_cart_items(db: Session, user_id: int, items: list[dict]) -> None:
    for item in items:
        dish_id = item.get("dish_id")
        quantity = int(item.get("quantity") or 0)
        if not dish_id or quantity <= 0:
            continue

        cart_item = (
            db.query(CartItem)
            .filter(
                CartItem.user_id == user_id,
                CartItem.dish_id == dish_id,
            )
            .first()
        )
        if not cart_item:
            continue

        remaining_quantity = cart_item.quantity - quantity
        if remaining_quantity > 0:
            cart_item.quantity = remaining_quantity
        else:
            db.delete(cart_item)


def _finalize_pending_checkout(
    db: Session,
    pending_checkout: PendingStripeCheckout,
) -> Order:
    if pending_checkout.order_id:
        order = (
            db.query(Order)
            .filter(Order.id == pending_checkout.order_id)
            .first()
        )
        if order:
            if pending_checkout.status != "paid":
                pending_checkout.status = "paid"
            if pending_checkout.completed_at is None:
                pending_checkout.completed_at = datetime.utcnow()
            return order

    existing_payment = (
        db.query(Payment)
        .filter(Payment.stripe_payment_intent == pending_checkout.payment_intent_id)
        .order_by(Payment.id.desc())
        .first()
    )
    if existing_payment and existing_payment.order_id:
        pending_checkout.order_id = existing_payment.order_id
        pending_checkout.status = "paid"
        if pending_checkout.completed_at is None:
            pending_checkout.completed_at = datetime.utcnow()
        order = (
            db.query(Order)
            .filter(Order.id == existing_payment.order_id)
            .first()
        )
        if order:
            return order

    order = Order(
        user_id=pending_checkout.user_id,
        total_price=pending_checkout.total_price,
        delivery_fee=pending_checkout.delivery_fee,
        distance_km=pending_checkout.distance_km,
        pickup_address=pending_checkout.pickup_address,
        delivery_address=pending_checkout.delivery_address,
        estimated_delivery_minutes=pending_checkout.estimated_delivery_minutes,
        status="confirmed",
        payment_method="stripe",
    )
    db.add(order)
    db.flush()

    for item in pending_checkout.cart_snapshot or []:
        db.add(
            OrderItem(
                order_id=order.id,
                dish_id=item.get("dish_id"),
                dish_name=item.get("dish_name"),
                dish_image=item.get("dish_image"),
                dish_price=item.get("dish_price"),
                quantity=item.get("quantity"),
            )
        )

    db.add(
        Payment(
            order_id=order.id,
            amount=pending_checkout.total_price,
            method="stripe",
            status="paid",
            stripe_payment_intent=pending_checkout.payment_intent_id,
            paid_at=datetime.utcnow(),
        )
    )

    _clear_cart_items(
        db,
        pending_checkout.user_id,
        pending_checkout.cart_snapshot or [],
    )

    pending_checkout.order_id = order.id
    pending_checkout.status = "paid"
    pending_checkout.completed_at = datetime.utcnow()
    return order


def _update_pending_checkout_status(
    db: Session,
    payment_intent_id: str | None,
    status: str,
) -> None:
    if not payment_intent_id:
        return

    pending_checkout = (
        db.query(PendingStripeCheckout)
        .filter(PendingStripeCheckout.payment_intent_id == payment_intent_id)
        .first()
    )
    if pending_checkout and not pending_checkout.order_id:
        pending_checkout.status = status
        db.commit()

# ==============================
# 1️⃣ CREATE PAYMENT INTENT
# ==============================
@router.post("/create", response_model=PaymentResponse)
def create_payment(
    request: PaymentCreateRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    order = db.query(Order).filter(
        Order.id == request.order_id,
        Order.user_id == user.id
    ).first()

    if not order:
        raise HTTPException(status_code=404, detail="Không tìm thấy order")

    if (order.payment_method or "").strip().lower() != "stripe":
        raise HTTPException(status_code=400, detail="Order nay khong su dung Stripe")

    intent = stripe.PaymentIntent.create(
        amount=int(order.total_price * 100),
        currency="usd",
        metadata={
            "order_id": str(order.id)
        }
    )

    payment = Payment(
        order_id=order.id,
        amount=order.total_price,
        method="stripe",
        status="pending",
        stripe_payment_intent=intent["id"]
    )

    db.add(payment)
    db.commit()
    db.refresh(payment)

    return {
        "client_secret": intent["client_secret"],
        "payment_id": payment.id
    }


@router.post("/confirm-checkout/{checkout_id}")
def confirm_checkout(
    checkout_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    pending_checkout = (
        db.query(PendingStripeCheckout)
        .filter(
            PendingStripeCheckout.id == checkout_id,
            PendingStripeCheckout.user_id == user.id,
        )
        .with_for_update()
        .first()
    )
    if not pending_checkout:
        raise HTTPException(status_code=404, detail="Khong tim thay checkout")

    if pending_checkout.order_id:
        return {"status": "paid", "order_id": pending_checkout.order_id}

    if not pending_checkout.payment_intent_id:
        raise HTTPException(status_code=400, detail="Checkout chua co payment intent")

    try:
        intent = stripe.PaymentIntent.retrieve(pending_checkout.payment_intent_id)
    except stripe.error.StripeError as exc:
        raise HTTPException(
            status_code=400,
            detail=f"Khong kiem tra duoc giao dich Stripe: {str(exc)}",
        ) from exc

    intent_status = (intent.get("status") or "").lower()
    if intent_status == "succeeded":
        order = _finalize_pending_checkout(db, pending_checkout)
        db.commit()
        return {"status": "paid", "order_id": order.id}

    pending_checkout.status = intent_status or pending_checkout.status
    db.commit()
    return {"status": pending_checkout.status, "order_id": None}

# ==============================
# 2️⃣ STRIPE WEBHOOK
# ==============================
@router.post("/webhook")
async def stripe_webhook(request: Request, db: Session = Depends(get_db)):

    payload = await request.body()
    sig_header = request.headers.get("stripe-signature")

    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, endpoint_secret
        )
    except Exception:
        raise HTTPException(status_code=400, detail="Webhook Error")

    if event["type"] == "payment_intent.succeeded":
        intent = event["data"]["object"]
        metadata = intent.get("metadata") or {}
        pending_checkout_id = metadata.get("pending_checkout_id")

        if pending_checkout_id:
            pending_checkout = (
                db.query(PendingStripeCheckout)
                .filter(PendingStripeCheckout.id == int(pending_checkout_id))
                .with_for_update()
                .first()
            )
            if pending_checkout:
                pending_checkout.status = "paid"
                _finalize_pending_checkout(db, pending_checkout)
                db.commit()
            return {"status": "success"}

        order_id = metadata.get("order_id")
        if not order_id:
            return {"status": "ignored"}

        payment = db.query(models.Payment)\
            .filter(models.Payment.stripe_payment_intent == intent["id"])\
            .first()

        if payment and payment.status != "paid":
            payment.status = "paid"
            payment.paid_at = datetime.utcnow()

            order = db.query(models.Order)\
                .filter(models.Order.id == int(order_id)).first()

            if order:
                order.status = "confirmed"
                order_items = (
                    db.query(OrderItem)
                    .filter(OrderItem.order_id == order.id)
                    .all()
                )

                cart_snapshot = [
                    {
                        "dish_id": order_item.dish_id,
                        "quantity": order_item.quantity,
                    }
                    for order_item in order_items
                ]
                _clear_cart_items(db, order.user_id, cart_snapshot)

            db.commit()

    if event["type"] == "payment_intent.payment_failed":
        intent = event["data"]["object"]
        _update_pending_checkout_status(db, intent.get("id"), "failed")

    if event["type"] == "payment_intent.canceled":
        intent = event["data"]["object"]
        _update_pending_checkout_status(db, intent.get("id"), "canceled")

    return {"status": "success"}

# ==============================
# 3️⃣ CHECK STATUS
# ==============================
@router.get("/check-status/{order_id}")
def check_payment_status(
    order_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    order = db.query(models.Order).filter(
        models.Order.id == order_id,
        models.Order.user_id == user.id
    ).first()
    if not order:
        raise HTTPException(status_code=404, detail="Khong tim thay order")

    payment = db.query(models.Payment)\
        .filter(models.Payment.order_id == order_id)\
        .order_by(models.Payment.id.desc())\
        .first()

    if not payment:
        raise HTTPException(status_code=404, detail="Chưa có thanh toán")

    return {"status": payment.status}
