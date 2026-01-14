# routers/profile.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models import Profile
from pydantic import BaseModel
from typing import Optional

router = APIRouter(prefix="/profile", tags=["Profile"])

# ========== SCHEMA ==========
class ProfileCreate(BaseModel):
    name: str
    sdt: Optional[str] = None
    live: Optional[str] = None
    img: Optional[str] = None
    user_id: Optional[int] = None

class ProfileUpdate(BaseModel):
    name: Optional[str] = None
    sdt: Optional[str] = None
    live: Optional[str] = None
    img: Optional[str] = None

# ========== LẤY TẤT CẢ PROFILE (READ ALL) ==========
@router.get("/")
def get_all_profiles(db: Session = Depends(get_db)):
    """Lấy danh sách tất cả profile"""
    profiles = db.query(Profile).all()
    return profiles

# ========== LẤY 1 PROFILE THEO ID (READ ONE) ==========
@router.get("/{profile_id}")
def get_profile(profile_id: int, db: Session = Depends(get_db)):
    """Lấy thông tin 1 profile theo ID"""
    profile = db.query(Profile).filter(Profile.id == profile_id).first()
    if not profile:
        raise HTTPException(status_code=404, detail="Không tìm thấy profile")
    return profile

# ========== THÊM PROFILE MỚI (CREATE) ==========
@router.post("/")
def create_profile(profile: ProfileCreate, db: Session = Depends(get_db)):
    """Tạo profile mới"""
    new_profile = Profile(
        name=profile.name,
        sdt=profile.sdt,
        live=profile.live,
        img=profile.img,
        user_id=profile.user_id
    )
    db.add(new_profile)
    db.commit()
    db.refresh(new_profile)
    return {"message": "Tạo profile thành công", "profile": new_profile}

# ========== SỬA PROFILE (UPDATE) ==========
@router.put("/{profile_id}")
def update_profile(profile_id: int, profile: ProfileUpdate, db: Session = Depends(get_db)):
    """Cập nhật thông tin profile"""
    db_profile = db.query(Profile).filter(Profile.id == profile_id).first()
    if not db_profile:
        raise HTTPException(status_code=404, detail="Không tìm thấy profile")
    
    # Cập nhật các trường nếu có giá trị mới
    if profile.name is not None:
        db_profile.name = profile.name
    if profile.sdt is not None:
        db_profile.sdt = profile.sdt
    if profile.live is not None:
        db_profile.live = profile.live
    if profile.img is not None:
        db_profile.img = profile.img
    
    db.commit()
    db.refresh(db_profile)
    return {"message": "Cập nhật profile thành công", "profile": db_profile}

# ========== XÓA PROFILE (DELETE) ==========
@router.delete("/{profile_id}")
def delete_profile(profile_id: int, db: Session = Depends(get_db)):
    """Xóa profile"""
    db_profile = db.query(Profile).filter(Profile.id == profile_id).first()
    if not db_profile:
        raise HTTPException(status_code=404, detail="Không tìm thấy profile")
    
    db.delete(db_profile)
    db.commit()
    return {"message": "Xóa profile thành công"}