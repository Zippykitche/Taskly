import os

from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL") or os.getenv("DIRECT_URL") or "postgresql+psycopg://postgres:jayjose@localhost:5432/taskly_db"

# Automatic fix for Render IPv6 incompatibility:
# Supabase direct host db.<ref>.supabase.co is IPv6-only, which Render free instances cannot reach.
# Automatically rewrite to Supabase's shared IPv4 pooler:
if "db.qnwjqdiwtxunjooiunsf.supabase.co" in DATABASE_URL:
    DATABASE_URL = DATABASE_URL.replace("db.qnwjqdiwtxunjooiunsf.supabase.co", "aws-1-ap-south-1.pooler.supabase.com")
    if "postgres:" in DATABASE_URL and "postgres.qnwjqdiwtxunjooiunsf" not in DATABASE_URL:
        DATABASE_URL = DATABASE_URL.replace("postgres:", "postgres.qnwjqdiwtxunjooiunsf:", 1)

if DATABASE_URL.startswith("postgresql://"):
    DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+psycopg://", 1)

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
