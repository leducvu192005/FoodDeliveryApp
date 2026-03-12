from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session
from typing import Optional, List
from json import dumps as json_dumps, loads as json_loads
from datetime import datetime

from database import get_db
from models import DisplayProgram, DisplayProgramSeller, Seller, User, Dish
from dependencies import get_current_user, require_role

router = APIRouter(prefix="/display", tags=["Display Programs"])


# ==================== Schemas ====================

class CreateProgramRequest(BaseModel):
    title: str
    description: Optional[str] = None
    program_type: str = "featured"
    icon: str = "star"
    color: str = "#FF5722"
    start_date: str
    end_date: str
    max_sellers: int = 0


class UpdateProgramRequest(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    program_type: Optional[str] = None
    icon: Optional[str] = None
    color: Optional[str] = None
    start_date: Optional[str] = None
    end_date: Optional[str] = None
    is_active: Optional[bool] = None
    max_sellers: Optional[int] = None


# ==================== Admin: CRUD chương trình ====================

@router.get("/programs")
def list_programs(
    db: Session = Depends(get_db),
):
    programs = db.query(DisplayProgram).order_by(DisplayProgram.id.desc()).all()
    result = []
    for p in programs:
        seller_count = (
            db.query(DisplayProgramSeller)
            .filter(
                DisplayProgramSeller.program_id == p.id,
                DisplayProgramSeller.status == "joined",
            )
            .count()
        )
        result.append({
            "id": p.id,
            "title": p.title,
            "description": p.description,
            "program_type": p.program_type,
            "icon": p.icon,
            "color": p.color,
            "start_date": str(p.start_date) if p.start_date else None,
            "end_date": str(p.end_date) if p.end_date else None,
            "is_active": p.is_active,
            "max_sellers": p.max_sellers,
            "seller_count": seller_count,
            "created_at": str(p.created_at) if p.created_at else None,
        })
    return result


@router.post("/programs")
def create_program(
    body: CreateProgramRequest,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role("admin")),
):
    program = DisplayProgram(
        title=body.title,
        description=body.description,
        program_type=body.program_type,
        icon=body.icon,
        color=body.color,
        start_date=datetime.fromisoformat(body.start_date),
        end_date=datetime.fromisoformat(body.end_date),
        max_sellers=body.max_sellers,
    )
    db.add(program)
    db.commit()
    db.refresh(program)
    return {"id": program.id, "title": program.title}


@router.put("/programs/{program_id}")
def update_program(
    program_id: int,
    body: UpdateProgramRequest,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role("admin")),
):
    program = db.query(DisplayProgram).filter(DisplayProgram.id == program_id).first()
    if not program:
        raise HTTPException(status_code=404, detail="Khong tim thay chuong trinh")

    if body.title is not None:
        program.title = body.title
    if body.description is not None:
        program.description = body.description
    if body.program_type is not None:
        program.program_type = body.program_type
    if body.icon is not None:
        program.icon = body.icon
    if body.color is not None:
        program.color = body.color
    if body.start_date is not None:
        program.start_date = datetime.fromisoformat(body.start_date)
    if body.end_date is not None:
        program.end_date = datetime.fromisoformat(body.end_date)
    if body.is_active is not None:
        program.is_active = body.is_active
    if body.max_sellers is not None:
        program.max_sellers = body.max_sellers

    db.commit()
    return {"id": program.id, "title": program.title}


@router.delete("/programs/{program_id}")
def delete_program(
    program_id: int,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role("admin")),
):
    program = db.query(DisplayProgram).filter(DisplayProgram.id == program_id).first()
    if not program:
        raise HTTPException(status_code=404, detail="Khong tim thay chuong trinh")
    db.delete(program)
    db.commit()
    return {"detail": "Da xoa chuong trinh"}


# ==================== Admin: xem seller trong chương trình ====================

@router.get("/programs/{program_id}/sellers")
def get_program_sellers(
    program_id: int,
    db: Session = Depends(get_db),
    admin: User = Depends(require_role("admin")),
):
    entries = (
        db.query(DisplayProgramSeller, Seller)
        .join(Seller, DisplayProgramSeller.seller_id == Seller.id)
        .filter(
            DisplayProgramSeller.program_id == program_id,
            DisplayProgramSeller.status == "joined",
        )
        .all()
    )
    return [
        {
            "id": e.id,
            "seller_id": s.id,
            "seller_name": s.name,
            "seller_address": s.address,
            "joined_at": str(e.joined_at) if e.joined_at else None,
        }
        for e, s in entries
    ]


# ==================== Seller: xem + tham gia / rời chương trình ====================

@router.get("/seller/programs")
def get_programs_for_seller(
    db: Session = Depends(get_db),
    user: User = Depends(require_role("seller")),
):
    seller = db.query(Seller).filter(Seller.user_id == user.id).first()
    if not seller:
        raise HTTPException(status_code=404, detail="Chua co thong tin seller")

    programs = (
        db.query(DisplayProgram)
        .filter(DisplayProgram.is_active == True)
        .order_by(DisplayProgram.id.desc())
        .all()
    )

    result = []
    for p in programs:
        joined = (
            db.query(DisplayProgramSeller)
            .filter(
                DisplayProgramSeller.program_id == p.id,
                DisplayProgramSeller.seller_id == seller.id,
                DisplayProgramSeller.status == "joined",
            )
            .first()
        )
        seller_count = (
            db.query(DisplayProgramSeller)
            .filter(
                DisplayProgramSeller.program_id == p.id,
                DisplayProgramSeller.status == "joined",
            )
            .count()
        )
        result.append({
            "id": p.id,
            "title": p.title,
            "description": p.description,
            "program_type": p.program_type,
            "icon": p.icon,
            "color": p.color,
            "start_date": str(p.start_date) if p.start_date else None,
            "end_date": str(p.end_date) if p.end_date else None,
            "max_sellers": p.max_sellers,
            "seller_count": seller_count,
            "is_joined": joined is not None,
            "dish_show": _parse_dish_show(joined.dish_show) if joined else [],
        })
    return result


@router.post("/seller/programs/{program_id}/join")
def join_program(
    program_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_role("seller")),
):
    seller = db.query(Seller).filter(Seller.user_id == user.id).first()
    if not seller:
        raise HTTPException(status_code=404, detail="Chua co thong tin seller")

    program = db.query(DisplayProgram).filter(DisplayProgram.id == program_id).first()
    if not program:
        raise HTTPException(status_code=404, detail="Khong tim thay chuong trinh")
    if not program.is_active:
        raise HTTPException(status_code=400, detail="Chuong trinh da ket thuc")

    existing = (
        db.query(DisplayProgramSeller)
        .filter(
            DisplayProgramSeller.program_id == program_id,
            DisplayProgramSeller.seller_id == seller.id,
        )
        .first()
    )

    if existing:
        if existing.status == "joined":
            raise HTTPException(status_code=400, detail="Ban da tham gia chuong trinh nay")
        existing.status = "joined"
        db.commit()
        return {"detail": "Da tham gia lai chuong trinh"}

    if program.max_sellers > 0:
        current_count = (
            db.query(DisplayProgramSeller)
            .filter(
                DisplayProgramSeller.program_id == program_id,
                DisplayProgramSeller.status == "joined",
            )
            .count()
        )
        if current_count >= program.max_sellers:
            raise HTTPException(status_code=400, detail="Chuong trinh da du so luong")

    db.add(DisplayProgramSeller(
        program_id=program_id,
        seller_id=seller.id,
        status="joined",
    ))
    db.commit()
    return {"detail": "Tham gia thanh cong"}


@router.post("/seller/programs/{program_id}/leave")
def leave_program(
    program_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_role("seller")),
):
    seller = db.query(Seller).filter(Seller.user_id == user.id).first()
    if not seller:
        raise HTTPException(status_code=404, detail="Chua co thong tin seller")

    entry = (
        db.query(DisplayProgramSeller)
        .filter(
            DisplayProgramSeller.program_id == program_id,
            DisplayProgramSeller.seller_id == seller.id,
            DisplayProgramSeller.status == "joined",
        )
        .first()
    )
    if not entry:
        raise HTTPException(status_code=400, detail="Ban chua tham gia chuong trinh nay")

    entry.status = "removed"
    db.commit()
    return {"detail": "Da roi chuong trinh"}


class UpdateDishShowRequest(BaseModel):
    dish_ids: List[int]


@router.get("/seller/programs/{program_id}/my-dishes")
def get_seller_dishes_for_program(
    program_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(require_role("seller")),
):
    """Trả về danh sách tất cả món của seller kèm trạng thái đã chọn hay chưa."""
    seller = db.query(Seller).filter(Seller.user_id == user.id).first()
    if not seller:
        raise HTTPException(status_code=404, detail="Chua co thong tin seller")

    entry = (
        db.query(DisplayProgramSeller)
        .filter(
            DisplayProgramSeller.program_id == program_id,
            DisplayProgramSeller.seller_id == seller.id,
            DisplayProgramSeller.status == "joined",
        )
        .first()
    )
    if not entry:
        raise HTTPException(status_code=400, detail="Ban chua tham gia chuong trinh nay")

    dishes = db.query(Dish).filter(Dish.seller_id == user.id).all()
    selected_ids = _parse_dish_show(entry.dish_show)

    return {
        "selected_ids": selected_ids,
        "dishes": [
            {
                "id": d.id,
                "name": d.name,
                "img": d.img,
                "price": float(d.price),
            }
            for d in dishes
        ],
    }


@router.put("/seller/programs/{program_id}/dish-show")
def update_dish_show(
    program_id: int,
    body: UpdateDishShowRequest,
    db: Session = Depends(get_db),
    user: User = Depends(require_role("seller")),
):
    """Cập nhật danh sách món hiển thị cho chương trình."""
    seller = db.query(Seller).filter(Seller.user_id == user.id).first()
    if not seller:
        raise HTTPException(status_code=404, detail="Chua co thong tin seller")

    entry = (
        db.query(DisplayProgramSeller)
        .filter(
            DisplayProgramSeller.program_id == program_id,
            DisplayProgramSeller.seller_id == seller.id,
            DisplayProgramSeller.status == "joined",
        )
        .first()
    )
    if not entry:
        raise HTTPException(status_code=400, detail="Ban chua tham gia chuong trinh nay")

    # Validate dish_ids belong to this seller
    valid_dishes = db.query(Dish.id).filter(
        Dish.seller_id == user.id,
        Dish.id.in_(body.dish_ids),
    ).all()
    valid_ids = [d.id for d in valid_dishes]

    entry.dish_show = valid_ids
    from sqlalchemy import text
    db.execute(
        text("UPDATE display_program_sellers SET dish_show = :val::jsonb WHERE id = :id"),
        {"val": json_dumps(valid_ids), "id": entry.id},
    )
    db.commit()
    return {"detail": "Da cap nhat mon hien thi", "dish_show": valid_ids}


# ==================== Buyer: xem chương trình + món ăn ====================

@router.get("/buyer/programs")
def get_active_programs_for_buyer(
    db: Session = Depends(get_db),
):
    """Trả về danh sách chương trình đang active cho buyer."""
    programs = (
        db.query(DisplayProgram)
        .filter(DisplayProgram.is_active == True)
        .order_by(DisplayProgram.id.desc())
        .all()
    )

    result = []
    for p in programs:
        seller_count = (
            db.query(DisplayProgramSeller)
            .filter(
                DisplayProgramSeller.program_id == p.id,
                DisplayProgramSeller.status == "joined",
            )
            .count()
        )
        if seller_count == 0:
            continue
        result.append({
            "id": p.id,
            "title": p.title,
            "description": p.description,
            "program_type": p.program_type,
            "icon": p.icon,
            "color": p.color,
            "start_date": str(p.start_date) if p.start_date else None,
            "end_date": str(p.end_date) if p.end_date else None,
            "seller_count": seller_count,
            "max_sellers": p.max_sellers,
        })
    return result


def _parse_dish_show(raw):
    """Safely parse dish_show which may be a list or a JSON string."""
    if raw is None:
        return []
    if isinstance(raw, list):
        return raw
    if isinstance(raw, str):
        try:
            parsed = json_loads(raw)
            if isinstance(parsed, list):
                return parsed
        except Exception:
            pass
    return []


@router.get("/buyer/programs/{program_id}/dishes")
def get_program_dishes(
    program_id: int,
    db: Session = Depends(get_db),
):
    """Trả về danh sách món ăn từ các seller đã tham gia chương trình."""
    program = db.query(DisplayProgram).filter(DisplayProgram.id == program_id).first()
    if not program:
        raise HTTPException(status_code=404, detail="Khong tim thay chuong trinh")

    # Lấy danh sách seller entries đã tham gia (kèm dish_show)
    joined_entries = (
        db.query(DisplayProgramSeller)
        .filter(
            DisplayProgramSeller.program_id == program_id,
            DisplayProgramSeller.status == "joined",
        )
        .all()
    )

    if not joined_entries:
        return []

    # Map seller_id -> dish_show list
    seller_ids = [e.seller_id for e in joined_entries]
    sellers = db.query(Seller).filter(Seller.id.in_(seller_ids)).all()
    seller_map = {s.id: s for s in sellers}

    # Collect all allowed dish IDs from dish_show
    entry_by_seller_user = {}
    for e in joined_entries:
        s = seller_map.get(e.seller_id)
        if s:
            entry_by_seller_user[s.user_id] = _parse_dish_show(e.dish_show)

    seller_user_ids = list(entry_by_seller_user.keys())
    if not seller_user_ids:
        return []

    dishes = (
        db.query(Dish)
        .filter(Dish.seller_id.in_(seller_user_ids))
        .all()
    )

    result = []
    for d in dishes:
        allowed_ids = entry_by_seller_user.get(d.seller_id, [])
        # Only include dish if seller selected it (or if seller has no selection = show all)
        if allowed_ids and d.id not in allowed_ids:
            continue
        seller = d.seller
        result.append({
            "id": d.id,
            "name": d.name,
            "img": d.img,
            "price": float(d.price),
            "seller_id": d.seller_id,
            "category_id": d.category_id,
            "description": d.description,
            "seller_name": seller.name_shop if seller else None,
            "seller_address": seller.address_shop if seller else None,
            "seller_lat": seller.lat if seller else None,
            "seller_lng": seller.lng if seller else None,
        })

    return result
