from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session
from typing import List, Optional
import json

from database import get_db
from models import Topping, User
from dependencies import get_current_user

router = APIRouter(prefix="/api/topping", tags=["Topping"])

# Pydantic models
class ToppingItem(BaseModel):
    name: str
    price: float

class ToppingCreate(BaseModel):
    name: str
    min: Optional[int] = 0
    max: Optional[int] = 1
    items: List[ToppingItem] = []
    dish_ids: Optional[List[int]] = []

class ToppingUpdate(BaseModel):
    name: Optional[str] = None
    min: Optional[int] = None
    max: Optional[int] = None
    items: Optional[List[ToppingItem]] = None
    dish_ids: Optional[List[int]] = None

# ✅ GET tất cả topping
@router.get("/", response_model=List[dict])
def get_all_toppings(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Lấy danh sách tất cả topping (seller: của mình, buyer: tất cả)"""
    try:
        # Nếu là seller: chỉ lấy topping của seller đó
        # Nếu là buyer: lấy tất cả topping
        if current_user.role == 'seller':
            toppings = db.query(Topping).filter(
                Topping.seller_id == current_user.id
            ).order_by(Topping.id).all()
        else:
            toppings = db.query(Topping).order_by(Topping.id).all()
        
        result = []
        for topping in toppings:
            # items đã là dict/list từ JSON column
            items = topping.items if topping.items else []
            dish_ids = topping.dish_ids if topping.dish_ids else []
            
            result.append({
                "id": topping.id,
                "name": topping.name,
                "min": topping.min if hasattr(topping, 'min') else 0,
                "max": topping.max if hasattr(topping, 'max') else 1,
                "items": items,
                "dish_ids": dish_ids
            })
        
        return result
    
    except Exception as e:
        print(f"❌ Lỗi get topping: {e}")
        raise HTTPException(status_code=500, detail=f"Lỗi: {str(e)}")

# ✅ GET topping theo ID
@router.get("/{topping_id}", response_model=dict)
def get_topping(
    topping_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Lấy thông tin chi tiết một topping"""
    topping = db.query(Topping).filter(
        Topping.id == topping_id,
        Topping.seller_id == current_user.id
    ).first()
    
    if not topping:
        raise HTTPException(status_code=404, detail="Không tìm thấy topping")
    
    return {
        "id": topping.id,
        "name": topping.name,
        "min": topping.min if hasattr(topping, 'min') else 0,
        "max": topping.max if hasattr(topping, 'max') else 1,
        "items": topping.items if topping.items else [],
        "dish_ids": topping.dish_ids if topping.dish_ids else []
    }

# ✅ POST thêm topping
@router.post("/", response_model=dict)
def create_topping(
    topping: ToppingCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Thêm nhóm topping mới"""
    try:
        # Kiểm tra trùng tên trong danh sách của seller
        existing = db.query(Topping).filter(
            Topping.name == topping.name,
            Topping.seller_id == current_user.id
        ).first()
        if existing:
            raise HTTPException(status_code=400, detail="Nhóm topping đã tồn tại")
        
        # Chuyển items sang dict
        items_list = [item.dict() for item in topping.items]
        
        # Tạo topping mới
        new_topping = Topping(
            name=topping.name,
            seller_id=current_user.id,
            min=topping.min,
            max=topping.max,
            items=items_list,  # SQLAlchemy tự convert sang JSON
            dish_ids=topping.dish_ids
        )
        
        db.add(new_topping)
        db.commit()
        db.refresh(new_topping)
        
        return {"message": "Thêm nhóm topping thành công", "id": new_topping.id}
    
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        print(f"❌ Lỗi create topping: {e}")
        raise HTTPException(status_code=500, detail=f"Lỗi: {str(e)}")

# ✅ PUT cập nhật topping
@router.put("/{topping_id}", response_model=dict)
def update_topping(
    topping_id: int,
    topping: ToppingUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Cập nhật thông tin topping"""
    db_topping = db.query(Topping).filter(
        Topping.id == topping_id,
        Topping.seller_id == current_user.id
    ).first()
    
    if not db_topping:
        raise HTTPException(status_code=404, detail="Không tìm thấy topping")
    
    try:
        if topping.name is not None:
            db_topping.name = topping.name
        
        if topping.min is not None:
            db_topping.min = topping.min
            
        if topping.max is not None:
            db_topping.max = topping.max
        
        if topping.items is not None:
            items_list = [item.dict() for item in topping.items]
            db_topping.items = items_list
        
        if topping.dish_ids is not None:
            db_topping.dish_ids = topping.dish_ids
        
        db.commit()
        
        return {"message": "Cập nhật topping thành công"}
    
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Lỗi: {str(e)}")

# ✅ DELETE xóa topping
@router.delete("/{topping_id}", response_model=dict)
def delete_topping(
    topping_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Xóa topping"""
    topping = db.query(Topping).filter(
        Topping.id == topping_id,
        Topping.seller_id == current_user.id
    ).first()
    
    if not topping:
        raise HTTPException(status_code=404, detail="Không tìm thấy topping")
    
    try:
        db.delete(topping)
        db.commit()
        return {"message": "Xóa topping thành công"}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Lỗi: {str(e)}")