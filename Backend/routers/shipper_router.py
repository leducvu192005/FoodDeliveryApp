from datetime import datetime, timedelta
import asyncio

from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from auth import ALGORITHM, SECRET_KEY
import models
from database import SessionLocal, get_db
from dependencies import require_role
from services.distance_service import calculate_distance_km
from schemas import (
    ShipperCurrentOrderResponse,
    ShipperDashboardResponse,
    ShipperEarningsResponse,
    ShipperEarningsSummaryResponse,
    ShipperHomeResponse,
    ShipperOrderDetailResponse,
    ShipperLegacyOrderResponse,
    ShipperLocationRequest,
    ShipperLocationResponse,
    ShipperLocationUpdateRequest,
    ShipperMessageResponse,
    ShipperOnlineRequest,
    ShipperOrderHistoryResponse,
    ShipperProfileResponse,
    ShipperProfileUpdateRequest,
    ShipperRadiusRequest,
    ShipperRadiusResponse,
    ShipperStatusResponse,
)

router = APIRouter(prefix="/shipper", tags=["Shipper"])
legacy_router = APIRouter(tags=["Shipper"])
ws_router = APIRouter(tags=["Shipper"])

AVAILABLE_ORDER_STATUSES = ["pending", "confirmed", "ready_for_pickup"]
ACTIVE_ORDER_STATUSES = ["accepted", "picked_up"]


def _normalize_phone(phone: str | None) -> str:
    return (phone or "").strip()


def _today_start() -> datetime:
    now = datetime.now()
    return now.replace(hour=0, minute=0, second=0, microsecond=0)


def _parse_shipper_id(raw_id: str) -> int:
    try:
        return int(raw_id)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="shipper_id khong hop le") from exc


def _validate_requested_shipper(
    shipper: models.Shipper,
    raw_shipper_id: str | None,
) -> None:
    if raw_shipper_id is None or not raw_shipper_id.strip():
        return

    requested_id = _parse_shipper_id(raw_shipper_id)
    if shipper.id != requested_id:
        raise HTTPException(status_code=403, detail="shipper_id khong hop le")


def _get_open_session(db: Session, shipper_id: int) -> models.ShipperSession | None:
    return (
        db.query(models.ShipperSession)
        .filter(
            models.ShipperSession.shipper_id == shipper_id,
            models.ShipperSession.end_time.is_(None),
        )
        .order_by(models.ShipperSession.start_time.desc())
        .first()
    )


def _set_online_state(db: Session, shipper: models.Shipper, is_online: bool) -> models.Shipper:
    if bool(shipper.is_online) == bool(is_online):
        return shipper

    shipper.is_online = is_online
    shipper.updated_at = datetime.now()

    if shipper.is_online:
        if not _get_open_session(db, shipper.id):
            db.add(models.ShipperSession(shipper_id=shipper.id))
    else:
        open_session = _get_open_session(db, shipper.id)
        if open_session:
            open_session.end_time = datetime.now()

    db.commit()
    db.refresh(shipper)
    return shipper


def _ensure_shipper(db: Session, user: models.User) -> models.Shipper:
    normalized_phone = _normalize_phone(user.sdt)
    if not normalized_phone:
        raise HTTPException(
            status_code=400,
            detail="Tai khoan shipper chua co so dien thoai. Vui long cap nhat profile.",
        )

    shipper = db.query(models.Shipper).filter(models.Shipper.user_id == user.id).first()
    if shipper:
        changed = False
        if not _normalize_phone(shipper.phone):
            shipper.phone = normalized_phone
            changed = True
        if shipper.accept_radius is None:
            shipper.accept_radius = 5
            changed = True
        if user.full_name and shipper.full_name != user.full_name:
            shipper.full_name = user.full_name
            changed = True
        if changed:
            shipper.updated_at = datetime.now()
            db.commit()
            db.refresh(shipper)
        return shipper

    shipper = models.Shipper(
        user_id=user.id,
        full_name=user.full_name,
        phone=normalized_phone,
        avatar=None,
        verhice_type="motorbike",
        license_plate=None,
        is_online=False,
        rating=5.0,
        accept_radius=5,
    )
    db.add(shipper)
    db.commit()
    db.refresh(shipper)
    return shipper


def _get_shipper_from_ws_credentials(
    db: Session,
    token: str | None,
    shipper_id_raw: str | None,
) -> models.Shipper | None:
    if token:
        try:
            payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
            user_id = payload.get("user_id")
            if user_id is None:
                return None
        except JWTError:
            return None

        user = (
            db.query(models.User)
            .filter(models.User.id == user_id, models.User.role == "shipper")
            .first()
        )
        if not user:
            return None

        try:
            return _ensure_shipper(db, user)
        except HTTPException:
            return None

    if not shipper_id_raw:
        return None

    try:
        shipper_id = int(shipper_id_raw)
    except ValueError:
        return None

    return db.query(models.Shipper).filter(models.Shipper.id == shipper_id).first()


def _get_active_order(db: Session, shipper: models.Shipper) -> models.Order | None:
    return (
        db.query(models.Order)
        .filter(
            models.Order.shipper_id == shipper.id,
            models.Order.status.in_(ACTIVE_ORDER_STATUSES),
        )
        .order_by(models.Order.assigned_at.desc(), models.Order.created_at.desc())
        .first()
    )


def _available_orders_query(db: Session, shipper: models.Shipper):
    return (
        db.query(models.Order)
        .filter(
            models.Order.shipper_id.is_(None),
            models.Order.status.in_(AVAILABLE_ORDER_STATUSES),
        )
        .order_by(models.Order.created_at.desc())
    )


def _shipper_to_pickup_distance_km(
    shipper: models.Shipper,
    order: models.Order,
) -> float | None:
    if (
        shipper.lat is None
        or shipper.lng is None
        or order.pickup_lat is None
        or order.pickup_lng is None
    ):
        return None

    return calculate_distance_km(
        float(shipper.lat),
        float(shipper.lng),
        float(order.pickup_lat),
        float(order.pickup_lng),
    )


def _filter_orders_for_shipper(
    shipper: models.Shipper,
    orders: list[models.Order],
) -> list[models.Order]:
    accept_radius = float(shipper.accept_radius or 5)
    allowed_orders: list[models.Order] = []
    for order in orders:
        distance_to_pickup = _shipper_to_pickup_distance_km(shipper, order)
        if distance_to_pickup is None:
            continue
        if distance_to_pickup <= accept_radius:
            allowed_orders.append(order)
    return allowed_orders


def _find_shipper_profile(db: Session, user_id: int) -> models.Profile | None:
    return (
        db.query(models.Profile)
        .filter(models.Profile.user_id == user_id)
        .order_by(models.Profile.id.desc())
        .first()
    )


def _legacy_status(status: str | None) -> str:
    if status == "delivered":
        return "completed"
    return status or "pending"


def _string_or_default(value: str | None, default: str = "") -> str:
    return value or default


def _to_order_payload(order: models.Order, db: Session) -> dict:
    customer = db.query(models.User).filter(models.User.id == order.user_id).first()
    return {
        "id": order.id,
        "customer_name": _string_or_default(customer.full_name if customer else None, "Unknown"),
        "customer_phone": _string_or_default(customer.sdt if customer else None),
        "total_price": float(order.total_price or 0),
        "delivery_fee": float(order.delivery_fee or 0),
        "distance_km": float(order.distance_km or 0),
        "pickup_address": order.pickup_address or "Pending pickup address",
        "delivery_address": order.delivery_address or "Pending delivery address",
        "pickup_lat": float(order.pickup_lat) if order.pickup_lat is not None else None,
        "pickup_lng": float(order.pickup_lng) if order.pickup_lng is not None else None,
        "delivery_lat": float(order.delivery_lat) if order.delivery_lat is not None else None,
        "delivery_lng": float(order.delivery_lng) if order.delivery_lng is not None else None,
        "estimated_delivery_minutes": order.estimated_delivery_minutes,
        "status": order.status,
        "created_at": order.created_at,
    }


def _to_legacy_order_payload(order: models.Order, db: Session) -> dict:
    customer = db.query(models.User).filter(models.User.id == order.user_id).first()
    pickup_address = order.pickup_address or "Pending pickup address"
    return {
        "id": order.id,
        "customer_name": _string_or_default(customer.full_name if customer else None, "Unknown"),
        "customer_phone": _string_or_default(customer.sdt if customer else None),
        "restaurant_name": pickup_address,
        "pickup_address": pickup_address,
        "delivery_address": order.delivery_address or "Pending delivery address",
        "total_price": float(order.total_price or 0),
        "shipping_fee": float(order.delivery_fee or 0),
        "status": _legacy_status(order.status),
        "created_at": order.created_at,
        "delivered_at": order.delivered_at,
        "distance_km": float(order.distance_km or 0),
        "estimated_delivery_minutes": order.estimated_delivery_minutes,
        "pickup_lat": float(order.pickup_lat) if order.pickup_lat is not None else None,
        "pickup_lng": float(order.pickup_lng) if order.pickup_lng is not None else None,
        "delivery_lat": float(order.delivery_lat) if order.delivery_lat is not None else None,
        "delivery_lng": float(order.delivery_lng) if order.delivery_lng is not None else None,
    }


def _to_order_detail_payload(order: models.Order, db: Session) -> dict:
    payload = _to_legacy_order_payload(order, db)
    items = (
        db.query(models.OrderItem)
        .filter(models.OrderItem.order_id == order.id)
        .order_by(models.OrderItem.id.asc())
        .all()
    )
    payload["items"] = [
        {
            "id": item.id,
            "dish_name": item.dish_name or "Mon an",
            "quantity": int(item.quantity or 0),
            "unit_price": float(item.dish_price or 0),
        }
        for item in items
    ]
    return payload


def _to_shipper_home_payload(shipper: models.Shipper) -> dict:
    return {
        "id": shipper.id,
        "name": shipper.full_name,
        "phone": shipper.phone,
        "avatar": shipper.avatar,
        "is_online": bool(shipper.is_online),
        "lat": float(shipper.lat) if shipper.lat is not None else None,
        "lng": float(shipper.lng) if shipper.lng is not None else None,
        "last_location_update": shipper.last_location_update,
        "accept_radius": int(shipper.accept_radius or 5),
    }


def _to_shipper_profile_payload(
    db: Session,
    shipper: models.Shipper,
    user: models.User,
) -> dict:
    profile = _find_shipper_profile(db, user.id)
    open_session = _get_open_session(db, shipper.id)
    completed_orders = int(shipper.total_completed_orders or 0)
    cancelled_orders = (
        db.query(models.Order)
        .filter(
            models.Order.shipper_id == shipper.id,
            models.Order.status == "cancelled",
        )
        .count()
    )
    total_tracked_orders = completed_orders + cancelled_orders
    completion_rate = (
        round((completed_orders / total_tracked_orders) * 100, 1)
        if total_tracked_orders
        else (100.0 if completed_orders else 0.0)
    )

    return {
        "shipper_id": shipper.id,
        "user_id": user.id,
        "name": shipper.full_name or user.full_name or "",
        "email": user.email or "",
        "phone": shipper.phone or user.sdt or "",
        "address": profile.live if profile and profile.live else "",
        "avatar": shipper.avatar or (profile.img if profile else None),
        "vehicle_type": shipper.verhice_type,
        "license_plate": shipper.license_plate or "",
        "rating": float(shipper.rating or 0),
        "is_online": bool(shipper.is_online),
        "current_lat": float(shipper.lat) if shipper.lat is not None else None,
        "current_lng": float(shipper.lng) if shipper.lng is not None else None,
        "last_location_update": shipper.last_location_update,
        "accept_radius": int(shipper.accept_radius or 5),
        "completed_orders": completed_orders,
        "completion_rate": completion_rate,
        "online_since": open_session.start_time if open_session else None,
    }


def _get_today_delivered_orders(db: Session, shipper: models.Shipper) -> list[models.Order]:
    today_start = _today_start()
    return (
        db.query(models.Order)
        .filter(
            models.Order.shipper_id == shipper.id,
            models.Order.status == "delivered",
            models.Order.delivered_at.is_not(None),
            models.Order.delivered_at >= today_start,
        )
        .all()
    )


def _accept_order_for_shipper(
    db: Session,
    shipper: models.Shipper,
    order_id: int,
) -> models.Order:
    if not shipper.is_online:
        raise HTTPException(status_code=400, detail="Ban can bat Online de nhan don")

    active_order = _get_active_order(db, shipper)
    if active_order and active_order.id != order_id:
        raise HTTPException(status_code=409, detail="Ban dang co don hang chua hoan tat")

    order = db.query(models.Order).filter(models.Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Khong tim thay don")

    if order.shipper_id is not None and order.shipper_id != shipper.id:
        raise HTTPException(status_code=409, detail="Don da co shipper nhan")

    if order.shipper_id == shipper.id and order.status in ACTIVE_ORDER_STATUSES:
        return order

    if order.status not in AVAILABLE_ORDER_STATUSES:
        raise HTTPException(status_code=400, detail="Don khong o trang thai co the nhan")

    distance_to_pickup = _shipper_to_pickup_distance_km(shipper, order)
    if distance_to_pickup is None:
        raise HTTPException(status_code=400, detail="Khong xac dinh duoc vi tri shipper hoac diem lay hang")
    if distance_to_pickup > float(shipper.accept_radius or 5):
        raise HTTPException(status_code=400, detail="Don nam ngoai ban kinh nhan don")

    order.shipper_id = shipper.id
    order.status = "accepted"
    order.assigned_at = datetime.now()

    db.commit()
    db.refresh(order)
    return order


def _pickup_order_for_shipper(
    db: Session,
    shipper: models.Shipper,
    order_id: int,
) -> models.Order:
    order = db.query(models.Order).filter(models.Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Khong tim thay don")
    if order.shipper_id != shipper.id:
        raise HTTPException(status_code=403, detail="Ban khong duoc cap quyen cho don nay")
    if order.status == "picked_up":
        return order
    if order.status != "accepted":
        raise HTTPException(status_code=400, detail="Don chua o trang thai duoc lay hang")

    order.status = "picked_up"
    order.picked_up_at = datetime.now()
    db.commit()
    db.refresh(order)
    return order


def _deliver_order_for_shipper(
    db: Session,
    shipper: models.Shipper,
    order_id: int,
) -> models.Order:
    order = db.query(models.Order).filter(models.Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Khong tim thay don")
    if order.shipper_id != shipper.id:
        raise HTTPException(status_code=403, detail="Ban khong duoc cap quyen cho don nay")
    if order.status == "delivered":
        return order
    if order.status != "picked_up":
        raise HTTPException(status_code=400, detail="Don chua du dieu kien giao thanh cong")

    order.status = "delivered"
    order.delivered_at = datetime.now()
    if (order.payment_method or "").strip().lower() == "cod":
        payment = (
            db.query(models.Payment)
            .filter(models.Payment.order_id == order.id)
            .order_by(models.Payment.id.desc())
            .first()
        )
        if payment is None:
            payment = models.Payment(
                order_id=order.id,
                amount=float(order.total_price or 0),
                method="cod",
                status="paid",
                paid_at=order.delivered_at,
            )
            db.add(payment)
        else:
            payment.method = payment.method or "cod"
            payment.status = "paid"
            payment.paid_at = order.delivered_at
    shipper.total_completed_orders = int(shipper.total_completed_orders or 0) + 1
    db.commit()
    db.refresh(order)
    return order


def _reject_order_for_shipper(
    db: Session,
    shipper: models.Shipper,
    order_id: int,
) -> None:
    order = db.query(models.Order).filter(models.Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Khong tim thay don")
    if order.shipper_id != shipper.id:
        raise HTTPException(status_code=403, detail="Ban khong duoc cap quyen cho don nay")
    if order.status != "accepted":
        raise HTTPException(status_code=400, detail="Chi co the tu choi don chua lay hang")

    order.shipper_id = None
    order.status = "confirmed"
    order.assigned_at = None
    db.commit()


@router.get("/me", response_model=ShipperHomeResponse)
def get_shipper_me(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role("shipper")),
):
    shipper = _ensure_shipper(db, current_user)
    return _to_shipper_home_payload(shipper)


@router.get("/profile", response_model=ShipperProfileResponse)
def get_shipper_profile(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role("shipper")),
):
    shipper = _ensure_shipper(db, current_user)
    return _to_shipper_profile_payload(db, shipper, current_user)


@router.put("/profile", response_model=ShipperProfileResponse)
def update_shipper_profile(
    payload: ShipperProfileUpdateRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role("shipper")),
):
    shipper = _ensure_shipper(db, current_user)
    profile = _find_shipper_profile(db, current_user.id)

    if profile is None:
        profile = models.Profile(
            name=current_user.full_name or "",
            sdt=current_user.sdt,
            live=current_user.address or "",
            img=None,
            user_id=current_user.id,
        )
        db.add(profile)
        db.flush()

    if payload.name is not None:
        cleaned_name = payload.name.strip()
        shipper.full_name = cleaned_name
        current_user.full_name = cleaned_name
        profile.name = cleaned_name

    if payload.phone is not None:
        cleaned_phone = payload.phone.strip()
        shipper.phone = cleaned_phone
        current_user.sdt = cleaned_phone
        profile.sdt = cleaned_phone

    if payload.address is not None:
        cleaned_address = payload.address.strip()
        current_user.address = cleaned_address
        profile.live = cleaned_address
    if payload.lat is not None:
        profile.lat = payload.lat
    if payload.lng is not None:
        profile.lng = payload.lng

    shipper.updated_at = datetime.now()

    try:
        db.commit()
    except Exception as exc:
        db.rollback()
        raise HTTPException(
            status_code=400,
            detail="Khong the cap nhat thong tin shipper",
        ) from exc

    db.refresh(shipper)
    db.refresh(current_user)
    db.refresh(profile)
    return _to_shipper_profile_payload(db, shipper, current_user)


@router.get("/{shipper_id:int}", response_model=ShipperHomeResponse)
def get_shipper_by_id(
    shipper_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role("shipper")),
):
    shipper = _ensure_shipper(db, current_user)
    if shipper.id != shipper_id:
        raise HTTPException(status_code=403, detail="Ban khong co quyen truy cap shipper nay")
    return _to_shipper_home_payload(shipper)


@router.post("/location", response_model=ShipperLocationResponse)
def update_shipper_location(
    payload: ShipperLocationRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role("shipper")),
):
    shipper = _ensure_shipper(db, current_user)
    _validate_requested_shipper(shipper, payload.shipper_id)

    shipper.lat = payload.lat
    shipper.lng = payload.lng
    shipper.last_location_update = datetime.now()
    shipper.updated_at = datetime.now()
    db.commit()

    return {
        "message": "Location updated",
        "lat": shipper.lat,
        "lng": shipper.lng,
        "last_location_update": shipper.last_location_update,
    }


@router.post("/location-update", response_model=ShipperLocationResponse)
def update_shipper_location_legacy(
    payload: ShipperLocationUpdateRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role("shipper")),
):
    shipper = _ensure_shipper(db, current_user)
    _validate_requested_shipper(shipper, payload.shipper_id)
    shipper.lat = payload.lat
    shipper.lng = payload.lng
    shipper.last_location_update = datetime.now()
    shipper.updated_at = datetime.now()
    db.commit()

    return {
        "message": "Location updated",
        "lat": shipper.lat,
        "lng": shipper.lng,
        "last_location_update": shipper.last_location_update,
    }


@router.post("/online", response_model=ShipperStatusResponse)
def update_shipper_online(
    payload: ShipperOnlineRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role("shipper")),
):
    shipper = _ensure_shipper(db, current_user)
    _validate_requested_shipper(shipper, payload.shipper_id)

    shipper = _set_online_state(db, shipper, payload.is_online)
    return {"message": "Online status updated", "is_online": bool(shipper.is_online)}


@router.post("/go-online", response_model=ShipperStatusResponse)
def go_online(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role("shipper")),
):
    shipper = _ensure_shipper(db, current_user)
    shipper = _set_online_state(db, shipper, True)
    return {"message": "Shipper is online", "is_online": bool(shipper.is_online)}


@router.post("/go-offline", response_model=ShipperStatusResponse)
def go_offline(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role("shipper")),
):
    shipper = _ensure_shipper(db, current_user)
    shipper = _set_online_state(db, shipper, False)
    return {"message": "Shipper is offline", "is_online": bool(shipper.is_online)}


@router.post("/radius", response_model=ShipperRadiusResponse)
def update_shipper_radius(
    payload: ShipperRadiusRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role("shipper")),
):
    shipper = _ensure_shipper(db, current_user)
    _validate_requested_shipper(shipper, payload.shipper_id)

    if payload.radius_km not in {2, 5, 10}:
        raise HTTPException(status_code=400, detail="Ban kinh chi ho tro 2, 5, 10 km")

    shipper.accept_radius = payload.radius_km
    shipper.updated_at = datetime.now()
    db.commit()

    return {"message": "Radius updated", "accept_radius": shipper.accept_radius}


@router.get("/dashboard", response_model=ShipperDashboardResponse)
def get_dashboard(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role("shipper")),
):
    shipper = _ensure_shipper(db, current_user)
    today_start = _today_start()
    delivered_orders = _get_today_delivered_orders(db, shipper)

    today_earnings = sum(float(order.delivery_fee or 0) for order in delivered_orders)
    completed_orders_today = len(delivered_orders)
    total_distance_today = sum(float(order.distance_km or 0) for order in delivered_orders)

    session_minutes = 0
    sessions = (
        db.query(models.ShipperSession)
        .filter(
            models.ShipperSession.shipper_id == shipper.id,
            models.ShipperSession.start_time >= today_start - timedelta(hours=24),
        )
        .all()
    )
    now = datetime.now()
    for session in sessions:
        end_time = session.end_time or now
        effective_start = max(session.start_time, today_start)
        if end_time > effective_start:
            session_minutes += int((end_time - effective_start).total_seconds() // 60)

    active_order = _get_active_order(db, shipper)
    available_orders = []
    if not active_order:
        candidate_orders = _available_orders_query(db, shipper).limit(30).all()
        available_orders = _filter_orders_for_shipper(shipper, candidate_orders)[:12]

    return {
        "shipper_name": shipper.full_name,
        "rating": float(shipper.rating or 0),
        "is_online": bool(shipper.is_online),
        "online_minutes_today": session_minutes,
        "today_earnings": today_earnings,
        "completed_orders_today": completed_orders_today,
        "total_orders": (
            db.query(models.Order)
            .filter(
                models.Order.shipper_id == shipper.id,
                models.Order.status != "cancelled",
            )
            .count()
        ),
        "total_distance_today": total_distance_today,
        "active_order": _to_order_payload(active_order, db) if active_order else None,
        "available_orders": [_to_order_payload(order, db) for order in available_orders],
    }


@router.get("/earnings/today", response_model=ShipperEarningsResponse)
def get_today_earnings(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role("shipper")),
):
    shipper = _ensure_shipper(db, current_user)
    delivered_orders = _get_today_delivered_orders(db, shipper)
    return {
        "total_earnings": sum(float(order.delivery_fee or 0) for order in delivered_orders),
        "completed_orders": len(delivered_orders),
    }


@router.get("/earnings/summary", response_model=ShipperEarningsSummaryResponse)
def get_earnings_summary(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role("shipper")),
):
    shipper = _ensure_shipper(db, current_user)
    delivered_orders = (
        db.query(models.Order)
        .filter(
            models.Order.shipper_id == shipper.id,
            models.Order.status == "delivered",
            models.Order.delivered_at.is_not(None),
        )
        .all()
    )

    now = datetime.now()
    start_day = now.replace(hour=0, minute=0, second=0, microsecond=0)
    start_week = start_day - timedelta(days=start_day.weekday())
    start_month = start_day.replace(day=1)

    today = 0.0
    week = 0.0
    month = 0.0
    total = 0.0

    for order in delivered_orders:
        delivered_at = order.delivered_at
        fee = float(order.delivery_fee or 0)
        total += fee
        if delivered_at is None:
            continue
        if delivered_at >= start_month:
            month += fee
        if delivered_at >= start_week:
            week += fee
        if delivered_at >= start_day:
            today += fee

    total_orders = len(delivered_orders)
    average_per_order = total / total_orders if total_orders else 0.0
    return {
        "today": today,
        "week": week,
        "month": month,
        "total_earnings": total,
        "total_orders": total_orders,
        "average_per_order": average_per_order,
    }


@router.patch("/toggle-online", response_model=ShipperStatusResponse)
def toggle_online(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role("shipper")),
):
    shipper = _ensure_shipper(db, current_user)
    shipper = _set_online_state(db, shipper, not bool(shipper.is_online))
    return {"message": "Online status updated", "is_online": bool(shipper.is_online)}


@router.patch("/orders/{order_id}/accept")
def accept_order(
    order_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role("shipper")),
):
    shipper = _ensure_shipper(db, current_user)
    order = _accept_order_for_shipper(db, shipper, order_id)
    return {"message": "Nhan don thanh cong", "order": _to_order_payload(order, db)}


@router.patch("/orders/{order_id}/pickup")
def pickup_order(
    order_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role("shipper")),
):
    shipper = _ensure_shipper(db, current_user)
    order = _pickup_order_for_shipper(db, shipper, order_id)
    return {"message": "Da lay hang", "order": _to_order_payload(order, db)}


@router.patch("/orders/{order_id}/deliver")
def deliver_order(
    order_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role("shipper")),
):
    shipper = _ensure_shipper(db, current_user)
    order = _deliver_order_for_shipper(db, shipper, order_id)
    return {"message": "Giao hang thanh cong", "order": _to_order_payload(order, db)}


@legacy_router.get("/orders/available", response_model=list[ShipperLegacyOrderResponse])
def get_available_orders(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role("shipper")),
):
    shipper = _ensure_shipper(db, current_user)
    if _get_active_order(db, shipper):
        return []
    candidate_orders = _available_orders_query(db, shipper).limit(50).all()
    orders = _filter_orders_for_shipper(shipper, candidate_orders)[:20]
    return [_to_legacy_order_payload(order, db) for order in orders]


@legacy_router.get("/orders/all", response_model=list[ShipperLegacyOrderResponse])
def get_all_orders(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role("shipper")),
):
    _ensure_shipper(db, current_user)
    orders = (
        db.query(models.Order)
        .order_by(models.Order.created_at.desc(), models.Order.id.desc())
        .all()
    )
    return [_to_legacy_order_payload(order, db) for order in orders]


@legacy_router.get("/orders/current", response_model=ShipperCurrentOrderResponse)
def get_current_order(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role("shipper")),
):
    shipper = _ensure_shipper(db, current_user)
    order = _get_active_order(db, shipper)
    return {"order": _to_legacy_order_payload(order, db) if order else None}


@legacy_router.get("/orders/{order_id:int}", response_model=ShipperOrderDetailResponse)
def get_order_detail(
    order_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role("shipper")),
):
    shipper = _ensure_shipper(db, current_user)
    order = db.query(models.Order).filter(models.Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Khong tim thay don")

    can_access = order.shipper_id == shipper.id or (
        order.shipper_id is None and order.status in AVAILABLE_ORDER_STATUSES
    )
    if not can_access:
        raise HTTPException(status_code=403, detail="Ban khong duoc cap quyen cho don nay")

    return _to_order_detail_payload(order, db)


@legacy_router.get("/orders/history", response_model=ShipperOrderHistoryResponse)
def get_order_history(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role("shipper")),
):
    shipper = _ensure_shipper(db, current_user)
    orders = (
        db.query(models.Order)
        .filter(
            models.Order.shipper_id == shipper.id,
            models.Order.status.in_(["delivered", "cancelled"]),
        )
        .order_by(models.Order.delivered_at.desc(), models.Order.created_at.desc())
        .limit(50)
        .all()
    )
    return {"orders": [_to_legacy_order_payload(order, db) for order in orders]}


@legacy_router.post("/orders/{order_id}/accept", response_model=ShipperLegacyOrderResponse)
def accept_order_legacy(
    order_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role("shipper")),
):
    shipper = _ensure_shipper(db, current_user)
    order = _accept_order_for_shipper(db, shipper, order_id)
    return _to_legacy_order_payload(order, db)


@legacy_router.post("/orders/{order_id}/pickup", response_model=ShipperLegacyOrderResponse)
def pickup_order_legacy(
    order_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role("shipper")),
):
    shipper = _ensure_shipper(db, current_user)
    order = _pickup_order_for_shipper(db, shipper, order_id)
    return _to_legacy_order_payload(order, db)


@legacy_router.post("/orders/{order_id}/deliver", response_model=ShipperLegacyOrderResponse)
def deliver_order_legacy(
    order_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role("shipper")),
):
    shipper = _ensure_shipper(db, current_user)
    order = _deliver_order_for_shipper(db, shipper, order_id)
    return _to_legacy_order_payload(order, db)


@legacy_router.post("/orders/{order_id}/reject", response_model=ShipperMessageResponse)
def reject_order_legacy(
    order_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role("shipper")),
):
    shipper = _ensure_shipper(db, current_user)
    _reject_order_for_shipper(db, shipper, order_id)
    return {"message": "Da tu choi don"}


@ws_router.websocket("/ws/orders")
async def ws_orders(websocket: WebSocket):
    token = websocket.query_params.get("token")
    shipper_id_raw = websocket.query_params.get("shipper_id")
    db = SessionLocal()
    shipper = _get_shipper_from_ws_credentials(db, token, shipper_id_raw)
    if not shipper:
        db.close()
        await websocket.close(code=1008)
        return

    shipper_id = shipper.id
    await websocket.accept()

    try:
        while True:
            db.expire_all()
            shipper = db.query(models.Shipper).filter(models.Shipper.id == shipper_id).first()
            if not shipper:
                await websocket.send_json({"type": "orders", "orders": []})
                await asyncio.sleep(5)
                continue

            candidate_orders = _available_orders_query(db, shipper).limit(50).all()
            available_orders = _filter_orders_for_shipper(shipper, candidate_orders)[:20]

            payload = {
                "type": "orders",
                "orders": [
                    {
                        "order_id": order.id,
                        "pickup_lat": order.pickup_lat,
                        "pickup_lng": order.pickup_lng,
                        "distance": float(order.distance_km or 0),
                        "delivery_fee": float(order.delivery_fee or 0),
                    }
                    for order in available_orders
                ],
            }
            await websocket.send_json(payload)
            await asyncio.sleep(5)
    except WebSocketDisconnect:
        pass
    finally:
        db.close()
