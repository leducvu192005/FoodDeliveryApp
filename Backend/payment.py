from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from app.database import Base

class Payment(Base):
    __tablename__ = "payments"
    
    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id"), nullable=False)
    amount = Column(Float, nullable=False)
    payment_method = Column(String(50), default="sepay_bank_transfer")
    transaction_id = Column(String(100), unique=True, nullable=True)
    status = Column(String(20), default="pending")  
    paid_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.now)
    

    order = relationship("Order", back_populates="payments")