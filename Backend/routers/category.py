from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import List
from sqlalchemy.orm import Session

from database import get_db
from models import Category, User
from schemas import CategoryCreate, CategoryResponse
from dependencies import get_current_user

router = APIRouter(prefix="/api/category", tags=["Category"])

# ===== API =====
@router.post("/", response_model=dict)
def create_category(
    category: CategoryCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Kiểm tra xem seller đã có danh mục này chưa
    existing = db.query(Category).filter(
        Category.name == category.name,
        Category.seller_id == current_user.id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Danh mục đã tồn tại")

    new_category = Category(
        name=category.name,
        seller_id=current_user.id
    )
    db.add(new_category)
    db.commit()
    db.refresh(new_category)

    return {
        "success": True,
        "message": "Thêm danh mục thành công",
        "category_id": new_category.id
    }


@router.get("/", response_model=List[CategoryResponse])
def get_categories(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Nếu là seller: chỉ lấy danh mục của seller đó
    # Nếu là buyer/customer: lấy tất cả danh mục
    if current_user.role == 'seller':
        return db.query(Category).filter(
            Category.seller_id == current_user.id
        ).order_by(Category.id).all()
    else:
        # Buyer/Customer: xem tất cả categories
        return db.query(Category).order_by(Category.id).all()


@router.get("/{category_id}", response_model=CategoryResponse)
def get_category(
    category_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    category = db.query(Category).filter(
        Category.id == category_id,
        Category.seller_id == current_user.id
    ).first()
    if not category:
        raise HTTPException(status_code=404, detail="Không tìm thấy danh mục")
    return category


@router.put("/{category_id}", response_model=dict)
def update_category(
    category_id: int,
    category: CategoryCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    db_category = db.query(Category).filter(
        Category.id == category_id,
        Category.seller_id == current_user.id
    ).first()
    if not db_category:
        raise HTTPException(status_code=404, detail="Không tìm thấy danh mục")

    db_category.name = category.name
    db.commit()

    return {
        "success": True,
        "message": "Cập nhật danh mục thành công"
    }


@router.delete("/{category_id}", response_model=dict)
def delete_category(
    category_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    category = db.query(Category).filter(
        Category.id == category_id,
        Category.seller_id == current_user.id
    ).first()
    if not category:
        raise HTTPException(status_code=404, detail="Không tìm thấy danh mục")

    db.delete(category)
    db.commit()

    return {
        "success": True,
        "message": "Xóa danh mục thành công"
    }
