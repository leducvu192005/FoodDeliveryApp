from fastapi import APIRouter, HTTPException, Depends, UploadFile, File
from pydantic import BaseModel
from typing import List, Optional
from sqlalchemy.orm import Session
from datetime import datetime

from database import get_db
from models import Dish, Category
from supabase_client import supabase

router = APIRouter(prefix="/api/dish", tags=["Dish"])

# ===== Pydantic schemas =====
class DishCreate(BaseModel):
    name: str
    img: Optional[str] = None
    price: float
    category_id: int
    description: Optional[str] = None
    group: Optional[str] = None


class DishResponse(BaseModel):
    id: int
    name: str
    img: Optional[str]
    price: float
    category_id: int
    description: Optional[str]
    group: Optional[str]

    class Config:
        from_attributes = True


# ===== Upload image =====
@router.post("/upload-image", response_model=dict)
async def upload_dish_image(file: UploadFile = File(...)):
    try:
        content = await file.read()

        file_name = f"dishes/{int(datetime.now().timestamp())}_{file.filename}"

        supabase.storage.from_("dish-images").upload(
            file_name,
            content,
            {
                "content-type": file.content_type,
                "upsert": True,
            }
        )

        public_url = supabase.storage.from_("dish-images").get_public_url(file_name)

        return {
            "success": True,
            "image_url": public_url
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ===== Create dish =====
@router.post("/", response_model=dict)
def create_dish(
    dish: DishCreate,
    db: Session = Depends(get_db)
):
    category = db.query(Category).filter(Category.id == dish.category_id).first()
    if not category:
        raise HTTPException(status_code=400, detail="Danh mục không tồn tại")

    existing = (
        db.query(Dish)
        .filter(Dish.name == dish.name, Dish.category_id == dish.category_id)
        .first()
    )
    if existing:
        raise HTTPException(status_code=400, detail="Món ăn đã tồn tại trong danh mục này")

    new_dish = Dish(
        name=dish.name,
        img=dish.img,
        price=dish.price,
        category_id=dish.category_id,
        description=dish.description,
        group=dish.group
    )

    db.add(new_dish)
    db.commit()
    db.refresh(new_dish)

    return {
        "success": True,
        "message": "Thêm món ăn thành công",
        "dish_id": new_dish.id
    }


# ===== Get dishes =====
@router.get("/", response_model=List[DishResponse])
def get_dishes(
    category_id: Optional[int] = None,
    db: Session = Depends(get_db)
):
    query = db.query(Dish)
    if category_id:
        query = query.filter(Dish.category_id == category_id)

    return query.order_by(Dish.id).all()


# ===== Get single dish =====
@router.get("/{dish_id}", response_model=DishResponse)
def get_dish(
    dish_id: int,
    db: Session = Depends(get_db)
):
    dish = db.query(Dish).filter(Dish.id == dish_id).first()
    if not dish:
        raise HTTPException(status_code=404, detail="Không tìm thấy món ăn")
    return dish


# ===== Update dish =====
@router.put("/{dish_id}", response_model=dict)
def update_dish(
    dish_id: int,
    dish: DishCreate,
    db: Session = Depends(get_db)
):
    db_dish = db.query(Dish).filter(Dish.id == dish_id).first()
    if not db_dish:
        raise HTTPException(status_code=404, detail="Không tìm thấy món ăn")

    if not db.query(Category).filter(Category.id == dish.category_id).first():
        raise HTTPException(status_code=400, detail="Danh mục không tồn tại")

    db_dish.name = dish.name
    db_dish.img = dish.img
    db_dish.price = dish.price
    db_dish.category_id = dish.category_id
    db_dish.description = dish.description
    db_dish.group = dish.group

    db.commit()

    return {
        "success": True,
        "message": "Cập nhật món ăn thành công"
    }


# ===== Delete dish =====
@router.delete("/{dish_id}", response_model=dict)
def delete_dish(
    dish_id: int,
    db: Session = Depends(get_db)
):
    dish = db.query(Dish).filter(Dish.id == dish_id).first()
    if not dish:
        raise HTTPException(status_code=404, detail="Không tìm thấy món ăn")

    db.delete(dish)
    db.commit()

    return {
        "success": True,
        "message": "Xóa món ăn thành công"
    }
