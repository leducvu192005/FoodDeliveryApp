from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
import models
from dependencies import get_current_user,require_role
router = APIRouter(prefix="/shipper", tags=["Shipper"])
@router.patch("/toggle-online")
def toggle_online(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_role("shipper"))
):
    shipper = db.query(models.User).filter(models.User.id == current_user.id).first()
    if not shipper:
        raise HTTPException(status_code = 404, detail="Shipper không tồn tại")
    shipper.is_online = not shipper.is_online
    db.commit()
    db.refresh(shipper)
    return{
        "is_online": shipper.is_online
    }