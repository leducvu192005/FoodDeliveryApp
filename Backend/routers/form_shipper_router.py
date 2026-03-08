from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from database import get_db
from dependencies import get_current_user
from models import FormShipper, User

router = APIRouter(prefix="/form-shipper", tags=["Form Shipper"])


class FormShipperCreate(BaseModel):
    name: str
    phone: str
    cccd: str
    vehicle_registration: str
    license: str


@router.post("/register")
def register_shipper(
    payload: FormShipperCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    existing = (
        db.query(FormShipper)
        .filter(
            FormShipper.user_id == user.id,
            FormShipper.status.in_(["pending", "yes"]),
        )
        .first()
    )
    if existing:
        raise HTTPException(
            status_code=400,
            detail="Ban da gui don dang ky. Vui long cho duyet.",
        )

    form = FormShipper(
        user_id=user.id,
        name=payload.name,
        phone=payload.phone,
        email=user.email,
        cccd=payload.cccd,
        vehicle_registration=payload.vehicle_registration,
        license=payload.license,
        status="pending",
    )
    db.add(form)
    db.commit()
    db.refresh(form)

    return {"message": "Dang ky thanh cong. Vui long cho admin duyet.", "id": form.id}


@router.get("/status")
def get_shipper_form_status(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    form = (
        db.query(FormShipper)
        .filter(FormShipper.user_id == user.id)
        .order_by(FormShipper.id.desc())
        .first()
    )
    if not form:
        return {"status": None}

    return {
        "id": form.id,
        "status": form.status,
        "vehicle_registration": form.vehicle_registration,
    }
