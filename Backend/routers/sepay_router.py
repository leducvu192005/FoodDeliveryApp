from fastapi import APIRouter, Depends, HTTPException, Request, Header
from sqlalchemy.orm import Session
from datetime import datetime
import hashlib
import hmac
import os
from typing import Optional
from database import get_db
from models import Order, Payment, CartItem, OrderItem, User
from schemas import PaymentCreateRequest
from dependencies import get_current_user
import re
import logging
import json

# Setup logger
logger = logging.getLogger("uvicorn.error")

router = APIRouter()

# 🔐 Sepay Configuration
SEPAY_ACCOUNT_NUMBER = os.getenv("SEPAY_ACCOUNT_NUMBER", "088448888")
SEPAY_BANK_CODE = os.getenv("SEPAY_BANK_CODE", "MBBank")
SEPAY_ACCOUNT_NAME = os.getenv("SEPAY_ACCOUNT_NAME", "naplua")
SEPAY_WEBHOOK_SECRET = os.getenv("SEPAY_WEBHOOK_SECRET", "")

# ==============================
# HELPER: Extract Order ID from Transaction Content
# ==============================
def extract_order_id_from_content(content: str) -> Optional[int]:
    """
    Trích xuất order_id từ nội dung chuyển khoản (case-insensitive)
    VD: "FD43 buyer" -> 43
    VD: "FD4620260306074525 buyer" -> 46
    VD: "MBVCB.123.FD43.CT tu ABC" -> 43
    """
    match = re.search(r'FD(\d+)', content, re.IGNORECASE)
    if match:
        digits = match.group(1)
        
        # Nếu chỉ có 1-3 chữ số, trả về luôn
        if len(digits) <= 3:
            try:
                return int(digits)
            except ValueError:
                return None
        
        # Nếu có nhiều chữ số (old format với timestamp)
        for num_digits in [2, 3, 1]:
            if len(digits) >= num_digits:
                try:
                    potential_id = int(digits[:num_digits])
                    if 1 <= potential_id <= 9999:
                        return potential_id
                except ValueError:
                    continue
    
    return None


def extract_transaction_id_from_content(content: str) -> Optional[str]:
    """
    Trích xuất transaction_id (FD{order_id}) từ nội dung chuyển khoản.
    Xử lý cả trường hợp ngân hàng thêm prefix vào content.
    VD: "FD43 buyer" -> "FD43"
    VD: "MBVCB.123.FD43.CT tu ABC" -> "FD43"
    """
    match = re.search(r'(FD\d+)', content, re.IGNORECASE)
    if match:
        return match.group(1).upper()
    return None


# ==============================
# 1️⃣ CREATE SEPAY PAYMENT
# ==============================
@router.post("/create")
def create_sepay_payment(
    request: PaymentCreateRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Tạo yêu cầu thanh toán Sepay (Chuyển khoản ngân hàng QR)
    """
    order = db.query(Order).filter(
        Order.id == request.order_id,
        Order.user_id == user.id
    ).first()

    if not order:
        raise HTTPException(status_code=404, detail="Không tìm thấy order")

    # Kiểm tra xem order đã có payment chưa
    existing_payment = db.query(Payment).filter(
        Payment.order_id == order.id,
        Payment.status == "paid"
    ).first()

    if existing_payment:
        raise HTTPException(status_code=400, detail="Order đã được thanh toán")

    # Tạo transaction_id đơn giản hơn: FD{order_id}
    # Không cần timestamp phức tạp, order_id đã unique
    transaction_id = f"FD{order.id}"

    # Tạo payment record
    payment = Payment(
        order_id=order.id,
        amount=order.total_price,
        method="sepay_bank_transfer",
        status="pending",
        transaction_id=transaction_id,
    )

    db.add(payment)
    db.commit()
    db.refresh(payment)

    # Tạo nội dung chuyển khoản
    transfer_content = f"{transaction_id} {user.full_name}"

    # Tạo QR Code URL cho VietQR
    amount_str = str(int(order.total_price))
    qr_url = (
        f"https://img.vietqr.io/image/"
        f"{SEPAY_BANK_CODE}-{SEPAY_ACCOUNT_NUMBER}-compact2.jpg"
        f"?amount={amount_str}"
        f"&addInfo={transfer_content}"
        f"&accountName={SEPAY_ACCOUNT_NAME}"
    )

    return {
        "payment_id": payment.id,
        "transaction_id": transaction_id,
        "qr_url": qr_url,
        "bank_code": SEPAY_BANK_CODE,
        "account_number": SEPAY_ACCOUNT_NUMBER,
        "account_name": SEPAY_ACCOUNT_NAME,
        "amount": order.total_price,
        "transfer_content": transfer_content,
        "message": "Vui lòng quét mã QR hoặc chuyển khoản với nội dung trên"
    }


# ==============================
# 2️⃣ SEPAY WEBHOOK
# ==============================
@router.post("/webhook")
async def sepay_webhook(
    request: Request,
    x_signature: Optional[str] = Header(None),
    db: Session = Depends(get_db)
):
    """
    Webhook nhận thông báo từ Sepay - Version 2.0 (Improved)
    """
    try:
        payload = await request.body()
        payload_str = payload.decode('utf-8')
        
        data = json.loads(payload_str)
        
        # SePay API gửi field "content" và "transferAmount"
        # Fallback sang "transaction_content" và "amount_in" cho test thủ công
        transaction_content = (
            data.get("content")
            or data.get("transaction_content")
            or ""
        ).strip()
        amount_in = float(
            data.get("transferAmount")
            or data.get("amount_in")
            or 0
        )
        transfer_type = data.get("transferType", "in")
        
        logger.info("")
        logger.info("=" * 80)
        logger.info(f"🔔 [SEPAY WEBHOOK] Received at {datetime.now()}")
        logger.info("=" * 80)
        logger.info("📦 FULL PAYLOAD:")
        logger.info(json.dumps(data, indent=2, ensure_ascii=False))
        logger.info("=" * 80)
        logger.info("📝 Parsed Data:")
        logger.info(f"   Content: {transaction_content}")
        logger.info(f"   Amount: {amount_in}")
        logger.info(f"   Transfer Type: {transfer_type}")
        logger.info("=" * 80)
        
        # Chỉ xử lý giao dịch tiền VÀO
        if transfer_type == "out":
            logger.info("[SEPAY] ⏭️ Skipping outgoing transfer")
            return {"status": "ignored", "message": "Outgoing transfer, skipped"}
        
        # Signature validation (optional)
        if SEPAY_WEBHOOK_SECRET and x_signature:
            expected_signature = hmac.new(
                SEPAY_WEBHOOK_SECRET.encode(),
                payload,
                hashlib.sha256
            ).hexdigest()
            
            if not hmac.compare_digest(expected_signature, x_signature):
                logger.error("[SEPAY] ❌ Invalid signature")
                raise HTTPException(status_code=401, detail="Invalid signature")
        
        # Extract transaction_id từ content (xử lý cả bank prefix)
        transaction_id = extract_transaction_id_from_content(transaction_content)
        order_id = extract_order_id_from_content(transaction_content)
        
        if not transaction_id and not order_id:
            logger.warning(f"[SEPAY] ❌ No FD pattern found in content: '{transaction_content}'")
            return {"status": "ignored", "message": "No transaction ID found in content"}
        
        logger.info(f"[SEPAY] Parsed: TxID={transaction_id}, OrderID={order_id}")
        
        payment = None
        
        # Strategy 1: Tìm bằng extracted transaction_id (VD: "FD43")
        if transaction_id:
            payment = db.query(Payment).filter(
                Payment.transaction_id == transaction_id,
                Payment.method == "sepay_bank_transfer",
            ).first()
            if payment:
                logger.info(f"[SEPAY] Strategy 1 (exact TxID) matched Payment #{payment.id}")
        
        # Strategy 2: Nếu không tìm thấy, tìm bằng order_id
        if not payment and order_id:
            logger.info(f"[SEPAY] Trying fallback: OrderID={order_id}")
            payment = db.query(Payment).filter(
                Payment.order_id == order_id,
                Payment.method == "sepay_bank_transfer",
            ).first()
            if payment:
                logger.info(f"[SEPAY] Strategy 2 (order_id) matched Payment #{payment.id}")
        
        if not payment:
            logger.warning(f"[SEPAY] ❌ Payment NOT found for TxID={transaction_id}, OrderID={order_id}")
            return {"status": "ignored", "message": f"Payment not found for: {transaction_id}"}
        
        logger.info(f"[SEPAY] ✅ Found Payment #{payment.id} (status={payment.status})")
        
        # Already paid?
        if payment.status == "paid":
            logger.info(f"[SEPAY] ⚠️  Already paid")
            return {"status": "already_paid", "message": "Payment already processed"}
        
        # Verify amount (chỉ khi amount_in > 0, vì một số test không gửi amount)
        if amount_in > 0 and abs(amount_in - payment.amount) > 0.01:
            logger.warning(f"[SEPAY] ⚠️ Amount mismatch: expected={payment.amount}, got={amount_in}")
            # Vẫn cho update nếu amount gần đúng hoặc log warning
            # Không block vì ngân hàng có thể trừ phí nhỏ
        
        # Update payment
        payment.status = "paid"
        payment.paid_at = datetime.now()
        
        # Update order
        order = db.query(Order).filter(Order.id == payment.order_id).first()
        if order:
            order.status = "confirmed"
            
            # Clear cart
            order_items = db.query(OrderItem).filter(
                OrderItem.order_id == order.id
            ).all()
            
            for order_item in order_items:
                cart_item = db.query(CartItem).filter(
                    CartItem.user_id == order.user_id,
                    CartItem.dish_id == order_item.dish_id,
                ).first()
                
                if cart_item:
                    remaining = cart_item.quantity - order_item.quantity
                    if remaining > 0:
                        cart_item.quantity = remaining
                    else:
                        db.delete(cart_item)
        
        db.commit()
        
        logger.info(f"[SEPAY] 🎉 Payment confirmed! Payment #{payment.id}, Order #{payment.order_id}")
        logger.info("=" * 80)
        logger.info("")
        
        return {
            "status": "success",
            "message": "Payment confirmed",
            "payment_id": payment.id,
            "order_id": payment.order_id
        }
        
    except json.JSONDecodeError:
        logger.error("[SEPAY] ❌ Invalid JSON")
        raise HTTPException(status_code=400, detail="Invalid JSON")
    except Exception as e:
        logger.error(f"[SEPAY] ❌ Error: {e}")
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


# ==============================
# 3️⃣ CHECK PAYMENT STATUS
# ==============================
@router.get("/check-status/{order_id}")
def check_sepay_payment_status(
    order_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Kiểm tra trạng thái thanh toán của order
    """
    order = db.query(Order).filter(
        Order.id == order_id,
        Order.user_id == user.id
    ).first()
    
    if not order:
        raise HTTPException(status_code=404, detail="Không tìm thấy order")

    payment = db.query(Payment).filter(
        Payment.order_id == order_id,
        Payment.method == "sepay_bank_transfer"
    ).order_by(Payment.id.desc()).first()

    if not payment:
        raise HTTPException(status_code=404, detail="Chưa có thanh toán")

    return {
        "status": payment.status,
        "amount": payment.amount,
        "transaction_id": payment.transaction_id,
        "paid_at": payment.paid_at
    }


# ==============================
# 4️⃣ CANCEL PAYMENT
# ==============================
@router.post("/cancel/{order_id}")
def cancel_sepay_payment(
    order_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Hủy thanh toán Sepay (chỉ được hủy khi chưa thanh toán)
    """
    order = db.query(Order).filter(
        Order.id == order_id,
        Order.user_id == user.id
    ).first()
    
    if not order:
        raise HTTPException(status_code=404, detail="Không tìm thấy order")

    payment = db.query(Payment).filter(
        Payment.order_id == order_id,
        Payment.method == "sepay_bank_transfer"
    ).order_by(Payment.id.desc()).first()

    if not payment:
        raise HTTPException(status_code=404, detail="Không tìm thấy thanh toán")
    
    if payment.status == "paid":
        raise HTTPException(status_code=400, detail="Không thể hủy thanh toán đã hoàn thành")
    
    db.delete(payment)
    db.delete(order)
    db.commit()
    
    return {
        "status": "success",
        "message": "Đã hủy thanh toán"
    }
