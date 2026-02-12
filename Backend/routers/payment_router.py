from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from datetime import datetime
import stripe
import models, schemas
from database import get_db
from models import Order, Payment
from schemas import PaymentCreateRequest, PaymentResponse
router = APIRouter(prefix="/api/payment", tags=["Payment"])
import os
# 🔐 Stripe Keys
stripe.api_key = os.getenv("STRIPE_API_KEY", "test")
endpoint_secret = os.getenv("STRIPE_ENDPOINT_SECRET", "test")

# ==============================
# 1️⃣ CREATE PAYMENT INTENT
# ==============================
@router.post("/create", response_model=PaymentResponse)
def create_payment(
    request: PaymentCreateRequest,
    db: Session = Depends(get_db)
):

    # 1️⃣ Lấy order từ DB
    order = db.query(Order).filter(Order.id == request.order_id).first()

    if not order:
        raise HTTPException(status_code=404, detail="Không tìm thấy order")

    # 2️⃣ Tạo Stripe PaymentIntent
    intent = stripe.PaymentIntent.create(
        amount=int(order.total_price * 100),  # Stripe dùng cent
        currency="usd",  # đổi sang "vnd" nếu tài khoản hỗ trợ
        metadata={
            "order_id": str(order.id)
        }
    )

    # 3️⃣ Lưu payment vào DB
    payment = Payment(
        order_id=order.id,
        amount=order.total_price,
        status="pending",
        stripe_payment_intent=intent["id"]
    )

    db.add(payment)
    db.commit()
    db.refresh(payment)

    # 4️⃣ Trả client_secret cho Flutter
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

    # Thanh toán thành công
    if event["type"] == "payment_intent.succeeded":
        intent = event["data"]["object"]
        order_id = intent["metadata"]["order_id"]

        payment = db.query(models.Payment)\
            .filter(models.Payment.stripe_payment_intent == intent["id"])\
            .first()

        if payment:
            payment.status = "paid"
            payment.paid_at = datetime.utcnow()

            order = db.query(models.Order)\
                .filter(models.Order.id == int(order_id)).first()

            if order:
                order.status = "confirmed"

            db.commit()

    return {"status": "success"}


# ==============================
# 3️⃣ CHECK STATUS
# ==============================
@router.get("/check-status/{order_id}")
def check_payment_status(order_id: int, db: Session = Depends(get_db)):

    payment = db.query(models.Payment)\
        .filter(models.Payment.order_id == order_id)\
        .order_by(models.Payment.id.desc())\
        .first()

    if not payment:
        raise HTTPException(status_code=404, detail="Chưa có thanh toán")

    return {"status": payment.status}
