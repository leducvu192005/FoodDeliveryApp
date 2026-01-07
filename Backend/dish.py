from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import psycopg2
from typing import List, Optional

router = APIRouter(prefix="/api/dish", tags=["Dish"])

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
class DishCreate(BaseModel):
    name: str
    img: Optional[str] = None
    price: float
    category_id: int
    description: Optional[str] = None
    group: Optional[str] = None

class Dish(BaseModel):
    id: int
    name: str
    img: Optional[str] = None
    price: float
    category_id: int
    description: Optional[str] = None
    group: Optional[str] = None

# API endpoints
@router.post("/", response_model=dict)
async def create_dish(dish: DishCreate):
    """Thêm món ăn mới"""
    connection = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        
        # Kiểm tra category_id có tồn tại không
        cursor.execute("SELECT id FROM category WHERE id = %s", (dish.category_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=400, detail="Danh mục không tồn tại")
        
        # Kiểm tra xem món ăn đã tồn tại chưa
        cursor.execute("SELECT id FROM dish WHERE name = %s AND category_id = %s", 
                      (dish.name, dish.category_id))
        if cursor.fetchone():
            raise HTTPException(status_code=400, detail="Món ăn đã tồn tại trong danh mục này")
        
        # Thêm món ăn mới
        cursor.execute(
            """INSERT INTO dish (name, img, price, category_id, description, "group") 
               VALUES (%s, %s, %s, %s, %s, %s) RETURNING id""",
            (dish.name, dish.img, dish.price, dish.category_id, dish.description, dish.group)
        )
        dish_id = cursor.fetchone()[0]
        connection.commit()
        
        cursor.close()
        return {
            "success": True,
            "message": "Thêm món ăn thành công",
            "dish_id": dish_id
        }
        
    except HTTPException:
        raise
    except Exception as error:
        if connection:
            connection.rollback()
        print(f"❌ Lỗi: {error}")
        raise HTTPException(status_code=500, detail=str(error))
    finally:
        if connection:
            connection.close()

@router.get("/", response_model=List[Dish])
async def get_dishes(category_id: Optional[int] = None):
    """Lấy danh sách món ăn"""
    connection = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        
        if category_id:
            cursor.execute(
                """SELECT id, name, img, price, category_id, description, "group" 
                   FROM dish WHERE category_id = %s ORDER BY id""",
                (category_id,)
            )
        else:
            cursor.execute(
                """SELECT id, name, img, price, category_id, description, "group" 
                   FROM dish ORDER BY id"""
            )
        
        dishes = []
        for row in cursor.fetchall():
            dishes.append({
                "id": row[0],
                "name": row[1],
                "img": row[2],
                "price": float(row[3]),
                "category_id": row[4],
                "description": row[5],
                "group": row[6]
            })
        
        cursor.close()
        return dishes
        
    except Exception as error:
        print(f"❌ Lỗi: {error}")
        raise HTTPException(status_code=500, detail=str(error))
    finally:
        if connection:
            connection.close()

@router.get("/{dish_id}", response_model=Dish)
async def get_dish(dish_id: int):
    """Lấy thông tin chi tiết một món ăn"""
    connection = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        
        cursor.execute(
            """SELECT id, name, img, price, category_id, description, "group" 
               FROM dish WHERE id = %s""",
            (dish_id,)
        )
        row = cursor.fetchone()
        
        if not row:
            raise HTTPException(status_code=404, detail="Không tìm thấy món ăn")
        
        cursor.close()
        return {
            "id": row[0],
            "name": row[1],
            "img": row[2],
            "price": float(row[3]),
            "category_id": row[4],
            "description": row[5],
            "group": row[6]
        }
        
    except HTTPException:
        raise
    except Exception as error:
        print(f"❌ Lỗi: {error}")
        raise HTTPException(status_code=500, detail=str(error))
    finally:
        if connection:
            connection.close()

@router.put("/{dish_id}", response_model=dict)
async def update_dish(dish_id: int, dish: DishCreate):
    """Cập nhật món ăn"""
    connection = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        
        # Kiểm tra xem món ăn có tồn tại không
        cursor.execute("SELECT id FROM dish WHERE id = %s", (dish_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail="Không tìm thấy món ăn")
        
        # Cập nhật món ăn
        cursor.execute(
            """UPDATE dish 
               SET name = %s, img = %s, price = %s, category_id = %s, 
                   description = %s, "group" = %s 
               WHERE id = %s""",
            (dish.name, dish.img, dish.price, dish.category_id, 
             dish.description, dish.group, dish_id)
        )
        connection.commit()
        
        cursor.close()
        return {
            "success": True,
            "message": "Cập nhật món ăn thành công"
        }
        
    except HTTPException:
        raise
    except Exception as error:
        if connection:
            connection.rollback()
        print(f"❌ Lỗi: {error}")
        raise HTTPException(status_code=500, detail=str(error))
    finally:
        if connection:
            connection.close()

@router.delete("/{dish_id}", response_model=dict)
async def delete_dish(dish_id: int):
    """Xóa món ăn"""
    connection = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        
        # Kiểm tra xem món ăn có tồn tại không
        cursor.execute("SELECT id FROM dish WHERE id = %s", (dish_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail="Không tìm thấy món ăn")
        
        # Xóa món ăn
        cursor.execute("DELETE FROM dish WHERE id = %s", (dish_id,))
        connection.commit()
        
        cursor.close()
        return {
            "success": True,
            "message": "Xóa món ăn thành công"
        }
        
    except HTTPException:
        raise
    except Exception as error:
        if connection:
            connection.rollback()
        print(f"❌ Lỗi: {error}")
        raise HTTPException(status_code=500, detail=str(error))
    finally:
        if connection:
            connection.close()
