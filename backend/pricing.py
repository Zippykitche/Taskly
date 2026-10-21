from sqlalchemy import Column, Integer, String, Float, JSON
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime

Base = declarative_base()

class ServicePricing(Base):
    __tablename__ = "service_pricing"
    
    id = Column(Integer, primary_key=True, index=True)
    category = Column(String(50), nullable=False, unique=True)
    
    # Base pricing (in KES cents)
    base_price = Column(Integer, nullable=False)
    price_per_hour = Column(Integer, nullable=True)
    
    # Multipliers
    location_multiplier = Column(JSON, default=dict)
    urgency_multiplier = Column(JSON, default=dict)
    
    # AI complexity range
    min_complexity = Column(Float, default=1.0)
    max_complexity = Column(Float, default=2.0)
    
    commission_rate = Column(Float, default=0.15)