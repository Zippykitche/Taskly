# Taskly Backend

**TaskRabbit for Africa** - A two-sided marketplace connecting clients with local service providers (taskers).

## 🚀 Current Features

### ✅ Working Endpoints

**Tasks**
- `POST /tasks/` - Create a new task
- `GET /tasks/` - List all available tasks
- `GET /tasks/{id}` - Get task details
- `POST /tasks/{id}/claim` - Tasker claims a task
- `POST /tasks/{id}/complete` - Mark task as completed

**Users**
- `GET /users/` - List all users (basic endpoint)

**Reviews**
- `GET /reviews/` - List all reviews (basic endpoint)

### 🔧 Tech Stack

- **Framework:** FastAPI 0.1.0
- **Database:** PostgreSQL
- **ORM:** SQLAlchemy
- **Validation:** Pydantic
- **Server:** Uvicorn

### 📊 Database Schema

**Users Table**

id (Primary Key)
name
email (unique)
password (hashed)
role (client | tasker)
phone


**Tasks Table**

id (Primary Key)
title
description
price (KES)
location
status (posted | assigned | in_progress | completed)
client_id (Foreign Key → users)
tasker_id (Foreign Key → users, nullable)


**Reviews Table**

id (Primary Key)
rating (1-5)
comment
task_id (Foreign Key → tasks)
reviewer_id (Foreign Key → users)


## 🛠️ Setup Instructions

### Prerequisites
- Python 3.14+
- PostgreSQL installed and running
- Git

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/tjayearl/Taskly.git
cd Taskly/backend
```

2. **Create virtual environment** (recommended)
```bash
python -m venv venv
venv\Scripts\activate  # Windows
```

3. **Install dependencies**
```bash
pip install fastapi uvicorn sqlalchemy psycopg2-binary pydantic
```

4. **Configure database**

Create a PostgreSQL database:
```sql
CREATE DATABASE taskapp;
```

Update `database.py` with your credentials:
```python
DATABASE_URL = "postgresql://postgres:YOUR_PASSWORD@localhost:5432/taskapp"
```

5. **Create database tables**
```bash
python -c "from database import engine, Base; import models; Base.metadata.create_all(bind=engine)"
```

6. **Run the server**
```bash
python -m uvicorn main:app --reload
```

Server will start at: `http://127.0.0.1:8000`

API documentation: `http://127.0.0.1:8000/docs`

## 📖 API Usage Examples

### Create Test Users

```python
from sqlalchemy.orm import Session
from database import SessionLocal
import models

db = SessionLocal()

# Client user
client = models.User(
    name="John Client",
    email="client@test.com",
    password="password123",
    role=models.UserRole.client,
    phone="0712345678"
)
db.add(client)

# Tasker user
tasker = models.User(
    name="Jane Tasker",
    email="tasker@test.com",
    password="password123",
    role=models.UserRole.tasker,
    phone="0722334455"
)
db.add(tasker)
db.commit()
```

### Task Workflow

**1. Create a task (Client)**
```bash
curl -X POST "http://127.0.0.1:8000/tasks/?client_id=1" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Fix my sink",
    "description": "Kitchen sink is leaking",
    "price": 1500,
    "location": "Westlands, Nairobi"
  }'
```

**Response:**
```json
{
  "id": 1,
  "title": "Fix my sink",
  "description": "Kitchen sink is leaking",
  "price": 1500,
  "location": "Westlands, Nairobi",
  "status": "posted"
}
```

**2. List all tasks**
```bash
curl http://127.0.0.1:8000/tasks/
```

**3. Claim a task (Tasker)**
```bash
curl -X POST "http://127.0.0.1:8000/tasks/1/claim?tasker_id=2"
```

**Response:**
```json
{
  "message": "Task claimed successfully",
  "task": {
    "id": 1,
    "status": "assigned",
    "tasker_id": 2,
    ...
  }
}
```

**4. Complete the task**
```bash
curl -X POST http://127.0.0.1:8000/tasks/1/complete
```

**Response:**
```json
{
  "message": "Task marked as completed",
  "task": {
    "id": 1,
    "status": "completed",
    ...
  }
}
```

## 🧪 Testing

Run the included test script:

```bash
pip install requests
python test_api.py
```

This will:
1. Create a task
2. List all tasks
3. Claim the task
4. Complete the task

## 📁 Project Structure
backend/
├── routes/
│   ├── users.py          # User-related endpoints
│   ├── tasks.py          # Task marketplace logic
│   └── reviews.py        # Review endpoints
├── main.py               # FastAPI app entry point
├── database.py           # PostgreSQL connection
├── models.py             # SQLAlchemy database models
├── schemas.py            # Pydantic validation schemas
├── auth.py               # Authentication logic (WIP)
├── test_api.py           # API test script
└── .gitignore            # Git ignore rules

## 🚧 In Development

- [ ] User registration endpoint
- [ ] User login with JWT authentication
- [ ] Review creation endpoint
- [ ] M-Pesa payment integration
- [ ] Payment escrow logic
- [ ] Task search and filtering
- [ ] Real-time notifications
- [ ] Image upload for tasks

## 🎯 Roadmap

**Week 1** (Current)
- ✅ Task CRUD operations
- ⬜ User registration/login
- ⬜ Reviews system

**Week 2**
- ⬜ JWT authentication
- ⬜ Deploy to Render/Railway
- ⬜ Connect React Native frontend

**Week 3**
- ⬜ M-Pesa integration
- ⬜ Payment processing
- ⬜ Escrow logic

## 🔐 Environment Variables

Create a `.env` file (not committed to Git):

```env
DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@localhost:5432/taskapp
SECRET_KEY=your-secret-key-here
MPESA_CONSUMER_KEY=your-mpesa-key
MPESA_CONSUMER_SECRET=your-mpesa-secret
```

## 👥 Team

- **Backend Developer:** Tjay (FastAPI, PostgreSQL, API design)
- **Frontend Developer:** Zipporah (React Native, mobile UI)

## 📄 License

This project is private and proprietary.

## 🤝 Contributing

This is a private project. For questions or collaboration, contact the team directly.

---

**Status:** MVP in active development  
**Last Updated:** April 27, 2026  
**Server:** Running locally on http://127.0.0.1:8000