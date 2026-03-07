from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from database import get_db
from dependencies import get_current_user
from models import FormSeller, User

router = APIRouter(prefix="/form-seller", tags=["Form Seller"])


class FormSellerCreate(BaseModel):
    name: str
    phone: str
    cccd: str
    name_shop: str
    address: str


@router.post("/register")
def register_seller(
    payload: FormSellerCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    existing = (
        db.query(FormSeller)
        .filter(
            FormSeller.user_id == user.id,
            FormSeller.status.in_(["pending", "yes"]),
        )
        .first()
    )
    if existing:
        raise HTTPException(
            status_code=400,
            detail="Ban da gui don dang ky. Vui long cho duyet.",
        )

    form = FormSeller(
        user_id=user.id,
        name=payload.name,
        phone=payload.phone,
        email=user.email,
        cccd=payload.cccd,
        name_shop=payload.name_shop,
        address=payload.address,
        status="pending",
    )
    db.add(form)
    db.commit()
    db.refresh(form)

    return {"message": "Dang ky thanh cong. Vui long cho admin duyet.", "id": form.id}


@router.get("/status")
def get_seller_form_status(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    form = (
        db.query(FormSeller)
        .filter(FormSeller.user_id == user.id)
        .order_by(FormSeller.id.desc())
        .first()
    )
    if not form:
        return {"status": None}

    return {
        "id": form.id,
        "status": form.status,
        "name_shop": form.name_shop,
    }
