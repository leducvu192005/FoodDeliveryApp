from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import psycopg2
from typing import List, Optional

router = APIRouter(prefix="/api/category", tags=["Category"])

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
class CategoryCreate(BaseModel):
    name: str

class Category(BaseModel):
    id: int
    name: str

# API endpoints
@router.post("/", response_model=dict)
async def create_category(category: CategoryCreate):
    """Thêm danh mục mới"""
    connection = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        
        # Kiểm tra xem category đã tồn tại chưa
        cursor.execute("SELECT id FROM category WHERE name = %s", (category.name,))
        if cursor.fetchone():
            raise HTTPException(status_code=400, detail="Danh mục đã tồn tại")
        
        # Thêm category mới
        cursor.execute(
            "INSERT INTO category (name) VALUES (%s) RETURNING id",
            (category.name,)
        )
        category_id = cursor.fetchone()[0]
        connection.commit()
        
        cursor.close()
        return {
            "success": True,
            "message": "Thêm danh mục thành công",
            "category_id": category_id
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

@router.get("/", response_model=List[Category])
async def get_categories():
    """Lấy danh sách danh mục"""
    connection = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        
        cursor.execute("SELECT id, name FROM category ORDER BY id")
        
        categories = []
        for row in cursor.fetchall():
            categories.append({
                "id": row[0],
                "name": row[1]
            })
        
        cursor.close()
        return categories
        
    except Exception as error:
        print(f"❌ Lỗi: {error}")
        raise HTTPException(status_code=500, detail=str(error))
    finally:
        if connection:
            connection.close()

@router.get("/{category_id}", response_model=Category)
async def get_category(category_id: int):
    """Lấy thông tin chi tiết một danh mục"""
    connection = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        
        cursor.execute("SELECT id, name FROM category WHERE id = %s", (category_id,))
        row = cursor.fetchone()
        
        if not row:
            raise HTTPException(status_code=404, detail="Không tìm thấy danh mục")
        
        cursor.close()
        return {
            "id": row[0],
            "name": row[1]
        }
        
    except HTTPException:
        raise
    except Exception as error:
        print(f"❌ Lỗi: {error}")
        raise HTTPException(status_code=500, detail=str(error))
    finally:
        if connection:
            connection.close()

@router.put("/{category_id}", response_model=dict)
async def update_category(category_id: int, category: CategoryCreate):
    """Cập nhật danh mục"""
    connection = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        
        # Kiểm tra xem category có tồn tại không
        cursor.execute("SELECT id FROM category WHERE id = %s", (category_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail="Không tìm thấy danh mục")
        
        # Cập nhật category
        cursor.execute(
            "UPDATE category SET name = %s WHERE id = %s",
            (category.name, category_id)
        )
        connection.commit()
        
        cursor.close()
        return {
            "success": True,
            "message": "Cập nhật danh mục thành công"
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

@router.delete("/{category_id}", response_model=dict)
async def delete_category(category_id: int):
    """Xóa danh mục"""
    connection = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor()
        
        # Kiểm tra xem category có tồn tại không
        cursor.execute("SELECT id FROM category WHERE id = %s", (category_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail="Không tìm thấy danh mục")
        
        # Xóa category
        cursor.execute(
            "DELETE FROM category WHERE id = %s",
            (category_id,)
        )
        connection.commit()
        
        cursor.close()
        return {
            "success": True,
            "message": "Xóa danh mục thành công"
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
