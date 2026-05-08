import unittest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

import main
import auth
import routes.users as users_router
import routes.tasks as tasks_router
import routes.reviews as reviews_router
from database import Base

TEST_DATABASE_URL = "sqlite:///:memory:"

class TestTaskAPI(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.engine = create_engine(
            TEST_DATABASE_URL,
            connect_args={"check_same_thread": False},
            poolclass=StaticPool,
        )
        cls.TestingSessionLocal = sessionmaker(
            autocommit=False,
            autoflush=False,
            bind=cls.engine,
        )

        Base.metadata.create_all(bind=cls.engine)
        main.engine = cls.engine

        def get_test_db():
            db = cls.TestingSessionLocal()
            try:
                yield db
            finally:
                db.close()

        main.app.dependency_overrides[users_router.get_db] = get_test_db
        main.app.dependency_overrides[tasks_router.get_db] = get_test_db
        main.app.dependency_overrides[reviews_router.get_db] = get_test_db
        main.app.dependency_overrides[auth.get_db] = get_test_db

        cls.client = TestClient(main.app)

        client_response = cls.client.post(
            "/users/register",
            json={
                "name": "Client User",
                "email": "client@example.com",
                "password": "password123",
                "role": "client",
                "phone": "0710000000",
            },
        )
        cls.client_user_id = client_response.json()["user_id"]

        tasker_response = cls.client.post(
            "/users/register",
            json={
                "name": "Tasker User",
                "email": "tasker@example.com",
                "password": "password123",
                "role": "tasker",
                "phone": "0720000000",
            },
        )
        cls.tasker_user_id = tasker_response.json()["user_id"]

    def test_task_lifecycle(self):
        create_response = self.client.post(
            f"/tasks/?client_id={self.client_user_id}",
            json={
                "title": "Fix my sink",
                "description": "Kitchen sink is leaking",
                "price": 1500,
                "location": "Westlands",
            },
        )
        self.assertEqual(create_response.status_code, 200)
        task = create_response.json()
        self.assertEqual(task["status"], "posted")

        task_id = task["id"]

        list_response = self.client.get("/tasks/")
        self.assertEqual(list_response.status_code, 200)
        self.assertTrue(any(item["id"] == task_id for item in list_response.json()))

        claim_response = self.client.post(f"/tasks/{task_id}/claim?tasker_id={self.tasker_user_id}")
        self.assertEqual(claim_response.status_code, 200)
        self.assertEqual(claim_response.json()["task"]["status"], "assigned")

        complete_response = self.client.post(f"/tasks/{task_id}/complete")
        self.assertEqual(complete_response.status_code, 200)
        self.assertEqual(complete_response.json()["task"]["status"], "completed")

        search_response = self.client.get("/tasks/search?location=Westlands")
        self.assertEqual(search_response.status_code, 200)
        self.assertTrue(any(item["id"] == task_id for item in search_response.json()))

    @classmethod
    def tearDownClass(cls):
        cls.engine.dispose()

if __name__ == "__main__":
    unittest.main()
