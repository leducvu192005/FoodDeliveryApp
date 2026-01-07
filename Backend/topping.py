from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import psycopg2
import json
from typing import List, Optional

router = APIRouter(prefix="/api/topping", tags=["Topping"])

# Database connection function
def get_db_connection():
    try:
        connection = psycopg2.connect(
            host="localhost",          
            database="FoodDeliveryApp", 
            user="postgres",          
            password="NKLog0204205@", 
            port="5432"
        )
        return connection
    except (Exception, psycopg2.Error) as error:
        print(f"❌ Lỗi khi kết nối PostgreSQL: {error}")
        raise HTTPException(status_code=500, detail="Database connection error")

# Pydantic models
class ToppingItem(BaseModel):
    name: str
    price: float

class ToppingCreate(BaseModel):
    name: str
    items: List[ToppingItem] = []  # Danh sách các topping items
    dish_ids: Optional[List[int]] = []  # Danh sách món áp dụng

class ToppingUpdate(BaseModel):
    name: Optional[str] = None
    items: Optional[List[ToppingItem]] = None
    dish_ids: Optional[List[int]] = None

class Topping(BaseModel):
    id: int
    name: str
    items: List[ToppingItem] = []
    dish_ids: Optional[List[int]] = []

# API endpoints
@router.post("/", response_model=dict)
async def create_topping(topping: ToppingCreate):
    """Thêm nhóm topping mới"""
    connection = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        
        # Kiểm tra xem topping đã tồn tại chưa
        cursor.execute("SELECT id FROM topping WHERE name = %s", (topping.name,))
        if cursor.fetchone():
            raise HTTPException(status_code=400, detail="Nhóm topping đã tồn tại")
        
        # Chuyển items sang JSON
        items_json = json.dumps([item.dict() for item in topping.items])
        
        # Thêm topping mới
        cursor.execute(
            "INSERT INTO topping (name, items, dish_ids) VALUES (%s, %s, %s) RETURNING id",
            (topping.name, items_json, topping.dish_ids)
        )
        topping_id = cursor.fetchone()[0]
        connection.commit()
        
        return {"message": "Thêm nhóm topping thành công", "id": topping_id}
    
    except HTTPException:
        raise
    except Exception as e:
        if connection:
            connection.rollback()
        raise HTTPException(status_code=500, detail=f"Lỗi khi thêm topping: {str(e)}")
    finally:
        if connection:
            cursor.close()
            connection.close()

@router.get("/", response_model=List[dict])
async def get_all_toppings():
    """Lấy danh sách tất cả topping"""
    connection = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        
        cursor.execute("SELECT id, name, items, dish_ids FROM topping ORDER BY id")
        rows = cursor.fetchall()
        
        toppings = []
        for row in rows:
            items = json.loads(row[2]) if row[2] else []
            toppings.append({
                "id": row[0],
                "name": row[1],
                "items": items,
                "dish_ids": row[3] if row[3] else []
            })
        
        return toppings
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi khi lấy danh sách topping: {str(e)}")
    finally:
        if connection:
            cursor.close()
            connection.close()

@router.get("/{topping_id}", response_model=dict)
async def get_topping(topping_id: int):
    """Lấy thông tin chi tiết một topping"""
    connection = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        
        cursor.execute("SELECT id, name, items, dish_ids FROM topping WHERE id = %s", (topping_id,))
        row = cursor.fetchone()
        
        if not row:
            raise HTTPException(status_code=404, detail="Không tìm thấy nhóm topping")
        
        items = json.loads(row[2]) if row[2] else []
        
        return {
            "id": row[0],
            "name": row[1],
            "items": items,
            "dish_ids": row[3] if row[3] else []
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi khi lấy thông tin topping: {str(e)}")
    finally:
        if connection:
            cursor.close()
            connection.close()

@router.put("/{topping_id}", response_model=dict)
async def update_topping(topping_id: int, topping: ToppingUpdate):
    """Cập nhật thông tin topping"""
    connection = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        
        # Kiểm tra topping có tồn tại không
        cursor.execute("SELECT id FROM topping WHERE id = %s", (topping_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail="Không tìm thấy nhóm topping")
        
        # Tạo câu query động dựa trên các field được cung cấp
        update_fields = []
        params = []
        
        if topping.name is not None:
            update_fields.append("name = %s")
            params.append(topping.name)
        
        if topping.items is not None:
            update_fields.append("items = %s")
            items_json = json.dumps([item.dict() for item in topping.items])
            params.append(items_json)
        
        if topping.dish_ids is not None:
            update_fields.append("dish_ids = %s")
            params.append(topping.dish_ids)
        
        if not update_fields:
            raise HTTPException(status_code=400, detail="Không có thông tin nào để cập nhật")
        
        params.append(topping_id)
        query = f"UPDATE topping SET {', '.join(update_fields)} WHERE id = %s"
        
        cursor.execute(query, params)
        connection.commit()
        
        return {"message": "Cập nhật nhóm topping thành công"}
    
    except HTTPException:
        raise
    except Exception as e:
        if connection:
            connection.rollback()
        raise HTTPException(status_code=500, detail=f"Lỗi khi cập nhật topping: {str(e)}")
    finally:
        if connection:
            cursor.close()
            connection.close()

@router.delete("/{topping_id}", response_model=dict)
async def delete_topping(topping_id: int):
    """Xóa một topping"""
    connection = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        
        # Kiểm tra topping có tồn tại không
        cursor.execute("SELECT id FROM topping WHERE id = %s", (topping_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail="Không tìm thấy nhóm topping")
        
        cursor.execute("DELETE FROM topping WHERE id = %s", (topping_id,))
        connection.commit()
        
        return {"message": "Xóa nhóm topping thành công"}
    
    except HTTPException:
        raise
    except Exception as e:
        if connection:
            connection.rollback()
        raise HTTPException(status_code=500, detail=f"Lỗi khi xóa topping: {str(e)}")
    finally:
        if connection:
            cursor.close()
            connection.close()
