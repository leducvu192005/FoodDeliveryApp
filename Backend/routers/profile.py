from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from auth import hash_password, verify_password
from database import get_db
from dependencies import get_current_user
from models import Profile, User

router = APIRouter(prefix="/profile", tags=["Profile"])


class ProfileCreate(BaseModel):
    name: str
    sdt: Optional[str] = None
    live: Optional[str] = None
    lat: Optional[float] = None
    lng: Optional[float] = None
    img: Optional[str] = None
    user_id: Optional[int] = None


class ProfileUpdate(BaseModel):
    name: Optional[str] = None
    sdt: Optional[str] = None
    live: Optional[str] = None
    lat: Optional[float] = None
    lng: Optional[float] = None
    img: Optional[str] = None


class PasswordUpdate(BaseModel):
    current_password: str
    new_password: str


def _find_latest_profile(db: Session, user_id: int) -> Optional[Profile]:
    return (
        db.query(Profile)
        .filter(Profile.user_id == user_id)
        .order_by(Profile.id.desc())
        .first()
    )


def _to_profile_payload(profile: Profile, user: User) -> dict:
    return {
        "id": profile.id,
        "name": (profile.name or user.full_name or "").strip(),
        "sdt": (profile.sdt or user.sdt or "").strip(),
        "live": (user.address or profile.live or "").strip(),
        "lat": user.lat if user.lat is not None else profile.lat,
        "lng": user.lng if user.lng is not None else profile.lng,
        "img": profile.img,
        "user_id": user.id,
        "email": (user.email or "").strip(),
        "status": user.status or "",
    }


@router.get("/me")
def get_my_profile(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    profile = _find_latest_profile(db, current_user.id)
    if profile is None:
        profile = Profile(
            name=current_user.full_name or "",
            sdt=current_user.sdt,
            live=current_user.address or "",
            img=None,
            user_id=current_user.id,
        )
        db.add(profile)
        db.commit()
        db.refresh(profile)
    else:
        changed = False
        if not current_user.address and profile.live:
            current_user.address = profile.live.strip()
            changed = True
        if current_user.address and not (profile.live or "").strip():
            profile.live = current_user.address.strip()
            changed = True
        if current_user.lat is None and profile.lat is not None:
            current_user.lat = profile.lat
            changed = True
        if current_user.lng is None and profile.lng is not None:
            current_user.lng = profile.lng
            changed = True
        if current_user.lat is not None and profile.lat is None:
            profile.lat = current_user.lat
            changed = True
        if current_user.lng is not None and profile.lng is None:
            profile.lng = current_user.lng
            changed = True
        if changed:
            db.commit()
            db.refresh(current_user)
            db.refresh(profile)

    return _to_profile_payload(profile, current_user)


@router.put("/me")
def upsert_my_profile(
    profile: ProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    db_profile = _find_latest_profile(db, current_user.id)
    if db_profile is None:
        db_profile = Profile(
            name=current_user.full_name or "",
            sdt=current_user.sdt,
            live=current_user.address or "",
            img=None,
            user_id=current_user.id,
        )
        db.add(db_profile)
        db.flush()

    if profile.name is not None:
        cleaned_name = profile.name.strip()
        db_profile.name = cleaned_name
        current_user.full_name = cleaned_name
    if profile.sdt is not None:
        cleaned_phone = profile.sdt.strip()
        db_profile.sdt = cleaned_phone
        current_user.sdt = cleaned_phone
    if profile.live is not None:
        cleaned_address = profile.live.strip()
        db_profile.live = cleaned_address
        current_user.address = cleaned_address
    if profile.lat is not None:
        db_profile.lat = profile.lat
        current_user.lat = profile.lat
    if profile.lng is not None:
        db_profile.lng = profile.lng
        current_user.lng = profile.lng
    if profile.img is not None:
        db_profile.img = profile.img

    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=400, detail="So dien thoai da ton tai hoac du lieu khong hop le")
    except Exception:
        db.rollback()
        raise HTTPException(status_code=500, detail="Khong the cap nhat profile")

    db.refresh(db_profile)
    db.refresh(current_user)

    return {
        "message": "Cap nhat profile thanh cong",
        "profile": _to_profile_payload(db_profile, current_user),
    }


@router.put("/me/password")
def update_my_password(
    payload: PasswordUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    current_password = payload.current_password.strip()
    new_password = payload.new_password.strip()

    if not verify_password(current_password, current_user.password_hash):
        raise HTTPException(status_code=400, detail="Mat khau hien tai khong dung")
    if len(new_password) < 6:
        raise HTTPException(status_code=400, detail="Mat khau moi phai co it nhat 6 ky tu")

    current_user.password_hash = hash_password(new_password)
    try:
        db.commit()
    except Exception:
        db.rollback()
        raise HTTPException(status_code=500, detail="Khong the cap nhat mat khau")
    return {"message": "Cap nhat mat khau thanh cong"}


@router.get("/")
def get_all_profiles(db: Session = Depends(get_db)):
    return db.query(Profile).all()


@router.get("/{profile_id}")
def get_profile(profile_id: int, db: Session = Depends(get_db)):
    profile = db.query(Profile).filter(Profile.id == profile_id).first()
    if not profile:
        raise HTTPException(status_code=404, detail="Khong tim thay profile")
    return profile


@router.post("/")
def create_profile(profile: ProfileCreate, db: Session = Depends(get_db)):
    new_profile = Profile(
        name=profile.name,
        sdt=profile.sdt,
        live=profile.live,
        lat=profile.lat,
        lng=profile.lng,
        img=profile.img,
        user_id=profile.user_id,
    )
    db.add(new_profile)
    db.commit()
    db.refresh(new_profile)
    return {"message": "Tao profile thanh cong", "profile": new_profile}


@router.put("/{profile_id}")
def update_profile(profile_id: int, profile: ProfileUpdate, db: Session = Depends(get_db)):
    db_profile = db.query(Profile).filter(Profile.id == profile_id).first()
    if not db_profile:
        raise HTTPException(status_code=404, detail="Khong tim thay profile")

    if profile.name is not None:
        db_profile.name = profile.name
    if profile.sdt is not None:
        db_profile.sdt = profile.sdt
    if profile.live is not None:
        db_profile.live = profile.live
        if db_profile.user_id is not None:
            owner = db.query(User).filter(User.id == db_profile.user_id).first()
            if owner:
                owner.address = profile.live
    if profile.lat is not None:
        db_profile.lat = profile.lat
        if db_profile.user_id is not None:
            owner = db.query(User).filter(User.id == db_profile.user_id).first()
            if owner:
                owner.lat = profile.lat
    if profile.lng is not None:
        db_profile.lng = profile.lng
        if db_profile.user_id is not None:
            owner = db.query(User).filter(User.id == db_profile.user_id).first()
            if owner:
                owner.lng = profile.lng
    if profile.img is not None:
        db_profile.img = profile.img

    db.commit()
    db.refresh(db_profile)
    return {"message": "Cap nhat profile thanh cong", "profile": db_profile}


@router.delete("/{profile_id}")
def delete_profile(profile_id: int, db: Session = Depends(get_db)):
    db_profile = db.query(Profile).filter(Profile.id == profile_id).first()
    if not db_profile:
        raise HTTPException(status_code=404, detail="Khong tim thay profile")

    db.delete(db_profile)
    db.commit()
    return {"message": "Xoa profile thanh cong"}
