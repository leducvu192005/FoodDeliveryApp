from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from datetime import datetime
import stripe
import models
from database import get_db
from models import CartItem, Order, OrderItem, Payment
from schemas import PaymentCreateRequest, PaymentResponse
import os
from dependencies import get_current_user
from models import User

router = APIRouter()

# 🔐 Stripe Keys
stripe.api_key = os.getenv("STRIPE_API_KEY", "test")
endpoint_secret = os.getenv("STRIPE_ENDPOINT_SECRET", "test")

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
        order_id = intent["metadata"]["order_id"]

        payment = db.query(models.Payment)\
            .filter(models.Payment.stripe_payment_intent == intent["id"])\
            .first()

        if payment and payment.status != "paid":
            payment.status = "paid"
            payment.paid_at = datetime.utcnow()

            order = db.query(models.Order)\
                .filter(models.Order.id == int(order_id)).first()

            if order:
                order.status = "shipper"
                order_items = (
                    db.query(OrderItem)
                    .filter(OrderItem.order_id == order.id)
                    .all()
                )

                # Clear cart only after successful payment.
                # Reduce quantity by purchased amount to avoid deleting newly added items.
                for order_item in order_items:
                    cart_item = (
                        db.query(CartItem)
                        .filter(
                            CartItem.user_id == order.user_id,
                            CartItem.dish_id == order_item.dish_id,
                        )
                        .first()
                    )
                    if not cart_item:
                        continue
                    remaining_quantity = cart_item.quantity - order_item.quantity
                    if remaining_quantity > 0:
                        cart_item.quantity = remaining_quantity
                    else:
                        db.delete(cart_item)

            db.commit()

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
