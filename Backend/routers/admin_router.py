from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session
from sqlalchemy import func

from database import get_db
from models import User, Order, Payment, Dish, Shipper, Seller, FormSeller, FormShipper
from dependencies import require_role

router = APIRouter(prefix="/admin", tags=["Admin"])

VALID_ROLES = {"buyer", "seller", "shipper", "admin"}


@router.get("/stats")
def get_admin_stats(
    db: Session = Depends(get_db),
    admin: User = Depends(require_role("admin")),
):
    total_users = db.query(func.count(User.id)).scalar() or 0
    total_buyers = db.query(func.count(User.id)).filter(User.role == "buyer").scalar() or 0
    total_sellers = db.query(func.count(User.id)).filter(User.role == "seller").scalar() or 0
    total_shippers = db.query(func.count(User.id)).filter(User.role == "shipper").scalar() or 0

    total_orders = db.query(func.count(Order.id)).scalar() or 0
    pending_orders = db.query(func.count(Order.id)).filter(Order.status == "pending").scalar() or 0
    done_orders = db.query(func.count(Order.id)).filter(Order.status == "done").scalar() or 0

    total_revenue = db.query(func.coalesce(func.sum(Payment.amount), 0)).filter(Payment.status == "paid").scalar() or 0

    total_dishes = db.query(func.count(Dish.id)).scalar() or 0

    return {
        "total_users": total_users,
        "total_buyers": total_buyers,
        "total_sellers": total_sellers,
        "total_shippers": total_shippers,
        "total_orders": total_orders,
        "pending_orders": pending_orders,
        "done_orders": done_orders,
        "total_revenue": float(total_revenue),
        "total_dishes": total_dishes,
    }


@router.get("/users")
def get_all_users(
    db: Session = Depends(get_db),
    admin: User = Depends(require_role("admin")),
):
    users = db.query(User).order_by(User.id.desc()).all()
    return [
        {
            "id": u.id,
            "full_name": u.full_name,
            "email": u.email,
            "sdt": u.sdt,
            "role": u.role,
            "is_active": u.is_active,
        }
        for u in users
    ]


@router.patch("/users/{user_id}/toggle-active")
def toggle_user_active(
    user_id: int,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role("admin")),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Khong tim thay user")
    if user.role == "admin":
        raise HTTPException(status_code=400, detail="Khong the thay doi trang thai admin")

    user.is_active = not user.is_active
    db.commit()
    return {"id": user.id, "is_active": user.is_active}


@router.get("/orders")
def get_all_orders(
    db: Session = Depends(get_db),
    admin: User = Depends(require_role("admin")),
):
    orders = db.query(Order).order_by(Order.id.desc()).limit(50).all()
    return [
        {
            "id": o.id,
            "user_id": o.user_id,
            "total_price": o.total_price,
            "delivery_fee": o.delivery_fee,
            "status": o.status,
            "payment_method": o.payment_method,
            "created_at": str(o.created_at) if o.created_at else None,
        }
        for o in orders
    ]


class ChangeRoleRequest(BaseModel):
    role: str


@router.patch("/users/{user_id}/change-role")
def change_user_role(
    user_id: int,
    body: ChangeRoleRequest,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role("admin")),
):
    new_role = body.role.strip().lower()
    if new_role not in VALID_ROLES:
        raise HTTPException(status_code=400, detail="Role khong hop le")

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Khong tim thay user")
    if user.id == admin.id:
        raise HTTPException(status_code=400, detail="Khong the doi role cua chinh minh")

    old_role = user.role
    user.role = new_role

    # Neu doi sang shipper thi tao ban ghi Shipper neu chua co
    if new_role == "shipper":
        existing = db.query(Shipper).filter(Shipper.user_id == user.id).first()
        if not existing:
            db.add(Shipper(
                user_id=user.id,
                full_name=user.full_name,
                phone=user.sdt or "",
                verhice_type="motorbike",
                is_online=False,
                rating=5.0,
            ))

    db.commit()
    return {"id": user.id, "old_role": old_role, "new_role": new_role}


@router.get("/seller-forms")
def get_seller_forms(
    db: Session = Depends(get_db),
    admin: User = Depends(require_role("admin")),
):
    forms = (
        db.query(FormSeller)
        .order_by(FormSeller.id.desc())
        .all()
    )
    return [
        {
            "id": f.id,
            "user_id": f.user_id,
            "name": f.name,
            "phone": f.phone,
            "cccd": f.cccd,
            "name_shop": f.name_shop,
            "address": f.address,
            "status": f.status,
            "created_at": str(f.created_at) if f.created_at else None,
        }
        for f in forms
    ]


class ReviewFormRequest(BaseModel):
    status: str  # "yes" or "no"


@router.patch("/seller-forms/{form_id}/review")
def review_seller_form(
    form_id: int,
    body: ReviewFormRequest,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role("admin")),
):
    new_status = body.status.strip().lower()
    if new_status not in {"yes", "no"}:
        raise HTTPException(status_code=400, detail="Status khong hop le")

    form = db.query(FormSeller).filter(FormSeller.id == form_id).first()
    if not form:
        raise HTTPException(status_code=404, detail="Khong tim thay don dang ky")

    form.status = new_status

    if new_status == "yes":
        user = db.query(User).filter(User.id == form.user_id).first()
        if user:
            # Nếu đã duyệt shipper rồi → done + role=all
            if user.status in ("done_shipper", "done"):
                user.status = "done"
                user.role = "all"
            else:
                user.status = "done_seller"
            user.address = form.address
            # Tạo bản ghi Seller nếu chưa có
            existing_seller = db.query(Seller).filter(Seller.user_id == user.id).first()
            if not existing_seller:
                db.add(Seller(
                    user_id=user.id,
                    name=form.name_shop or form.name,
                    status="off",
                    address=form.address,
                    phone=form.phone,
                    email=form.email,
                    cccd=form.cccd,
                    price=0,
                ))
    elif new_status == "no":
        user = db.query(User).filter(User.id == form.user_id).first()
        if user:
            # Chỉ set no_seller nếu chưa có role nào được duyệt
            if user.status not in ("done_shipper", "done"):
                user.status = "no_seller"

    db.commit()
    return {"id": form.id, "status": form.status}


@router.get("/shipper-forms")
def get_shipper_forms(
    db: Session = Depends(get_db),
    admin: User = Depends(require_role("admin")),
):
    forms = db.query(FormShipper).order_by(FormShipper.id.desc()).all()
    return [
        {
            "id": f.id,
            "user_id": f.user_id,
            "name": f.name,
            "phone": f.phone,
            "email": f.email,
            "cccd": f.cccd,
            "vehicle_registration": f.vehicle_registration,
            "license": f.license,
            "status": f.status,
            "created_at": str(f.created_at) if f.created_at else None,
        }
        for f in forms
    ]


@router.patch("/shipper-forms/{form_id}/review")
def review_shipper_form(
    form_id: int,
    body: ReviewFormRequest,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role("admin")),
):
    new_status = body.status.strip().lower()
    if new_status not in {"yes", "no"}:
        raise HTTPException(status_code=400, detail="Status khong hop le")

    form = db.query(FormShipper).filter(FormShipper.id == form_id).first()
    if not form:
        raise HTTPException(status_code=404, detail="Khong tim thay don dang ky")

    form.status = new_status

    user = db.query(User).filter(User.id == form.user_id).first()
    if user:
        user.full_name = form.name
        user.sdt = form.phone
        user.cccd = int(form.cccd) if form.cccd.isdigit() else user.cccd
        user.vehicle_registration = (
            int(form.vehicle_registration)
            if form.vehicle_registration.isdigit()
            else user.vehicle_registration
        )
        user.license = int(form.license) if form.license.isdigit() else user.license
        if new_status == "yes":
            # Nếu đã duyệt seller rồi → done + role=all
            if user.status in ("done_seller", "done"):
                user.status = "done"
                user.role = "all"
            else:
                user.status = "done_shipper"
            existing = db.query(Shipper).filter(Shipper.user_id == user.id).first()
            if not existing:
                db.add(
                    Shipper(
                        user_id=user.id,
                        full_name=form.name,
                        phone=form.phone,
                        verhice_type="motorbike",
                        is_online=False,
                        rating=5.0,
                    )
                )
        elif new_status == "no":
            # Chỉ set no_shipper nếu chưa có role nào được duyệt
            if user.status not in ("done_seller", "done"):
                user.status = "no_shipper"

    db.commit()
    return {"id": form.id, "status": form.status}


# ==================== Pending Users (registered as seller/shipper) ====================

@router.get("/pending-users")
def get_pending_users(
    type: str = "all",
    db: Session = Depends(get_db),
    admin: User = Depends(require_role("admin")),
):
    """List users with role='pending'. Filter by type: seller, shipper, or all."""
    query = db.query(User).filter(User.role == "pending")

    if type == "seller":
        query = query.filter(User.name_shop.isnot(None))
    elif type == "shipper":
        query = query.filter(User.vehicle_registration.isnot(None))

    users = query.order_by(User.id.desc()).all()
    return [
        {
            "id": u.id,
            "full_name": u.full_name,
            "email": u.email,
            "sdt": u.sdt,
            "cccd": str(u.cccd) if u.cccd else None,
            "name_shop": u.name_shop,
            "address_shop": u.address_shop,
            "vehicle_registration": str(u.vehicle_registration) if u.vehicle_registration else None,
            "license": str(u.license) if u.license else None,
            "status": u.status,
        }
        for u in users
    ]


class ReviewPendingUserRequest(BaseModel):
    status: str  # "yes" or "no"


@router.patch("/pending-users/{user_id}/review")
def review_pending_user(
    user_id: int,
    body: ReviewPendingUserRequest,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role("admin")),
):
    new_status = body.status.strip().lower()
    if new_status not in {"yes", "no"}:
        raise HTTPException(status_code=400, detail="Status khong hop le")

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Khong tim thay user")
    if user.role != "pending":
        raise HTTPException(status_code=400, detail="User nay khong o trang thai pending")

    user.status = new_status

    if new_status == "yes":
        # Determine intended role from registration data
        if user.name_shop:
            user.role = "seller"
            user.address = user.address_shop
        elif user.vehicle_registration:
            user.role = "shipper"
            # Create Shipper record if not exists
            existing = db.query(Shipper).filter(Shipper.user_id == user.id).first()
            if not existing:
                db.add(Shipper(
                    user_id=user.id,
                    full_name=user.full_name,
                    phone=user.sdt or "",
                    verhice_type="motorbike",
                    is_online=False,
                    rating=5.0,
                ))
    else:
        user.role = "fail"

    db.commit()
    return {"id": user.id, "status": user.status, "role": user.role}
