from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from database import get_db
from dependencies import get_current_user
from models import Dish, Favorite, User
from schemas import FavoriteResponse

router = APIRouter(prefix="/favorites", tags=["Favorites"])


@router.get("", response_model=list[FavoriteResponse])
def get_favorites(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    return (
        db.query(Favorite)
        .filter(Favorite.user_id == user.id)
        .order_by(Favorite.created_at.desc(), Favorite.id.desc())
        .all()
    )


@router.post("/{dish_id}", response_model=FavoriteResponse, status_code=status.HTTP_201_CREATED)
def add_favorite(
    dish_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    dish = db.query(Dish).filter(Dish.id == dish_id).first()
    if not dish:
        raise HTTPException(status_code=404, detail="Dish not found")

    favorite = (
        db.query(Favorite)
        .filter(Favorite.user_id == user.id, Favorite.dish_id == dish_id)
        .first()
    )
    if favorite:
        return favorite

    favorite = Favorite(
        user_id=user.id,
        dish_id=dish_id,
        created_at=datetime.utcnow(),
    )
    db.add(favorite)
    db.commit()
    db.refresh(favorite)
    return favorite


@router.delete("/{dish_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_favorite(
    dish_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    favorite = (
        db.query(Favorite)
        .filter(Favorite.user_id == user.id, Favorite.dish_id == dish_id)
        .first()
    )
    if not favorite:
        raise HTTPException(status_code=404, detail="Favorite not found")

    db.delete(favorite)
    db.commit()
