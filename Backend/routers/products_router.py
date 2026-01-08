from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session  
from typing import List
from database import get_db
from models import Product
from schemas import ProductCreate, ProductResponse
router = APIRouter(prefix="/products", tags=["Products"])
@router.post("/", response_model=ProductResponse)
def create_product(
    data: ProductCreate,
    db: Session = Depends(get_db)
):
    product = Product(
        name=data.name,
        description=data.description,
        price=data.price,
        create_by=data.create_by
    )
    db.add(product)
    db.commit()
    db.refresh(product)
    return product
@router.get("/", response_model=List[ProductResponse])
def list_products(db: Session = Depends(get_db)):
    return db.query(Product).all()
@router.get("/{product_id}", response_model=ProductResponse)
def get_product(
    product_id: int,
    db: Session = Depends(get_db)
):
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    return product
    