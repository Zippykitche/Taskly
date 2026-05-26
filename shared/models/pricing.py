from sqlalchemy import Column, Integer, String, Float, JSON
from datetime import datetime
from . import Base


class ServicePricing(Base):
    __tablename__ = "service_pricing"

    id = Column(Integer, primary_key=True, index=True)
    category = Column(String(50), nullable=False, unique=True)
    base_price = Column(Integer, nullable=False)
    price_per_hour = Column(Integer, nullable=True)
    location_multiplier = Column(JSON, default=dict)
    urgency_multiplier = Column(JSON, default=dict)
    min_complexity = Column(Float, default=1.0)
    max_complexity = Column(Float, default=2.0)
    commission_rate = Column(Float, default=0.15)

    def to_dict(self):
        return {
            "id": self.id,
            "category": self.category,
            "base_price": self.base_price / 100,
            "price_per_hour": self.price_per_hour / 100 if self.price_per_hour else None,
            "location_multiplier": self.location_multiplier,
            "urgency_multiplier": self.urgency_multiplier,
            "commission_rate": self.commission_rate,
        }
