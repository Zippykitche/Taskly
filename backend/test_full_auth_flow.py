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

class TestFullAuthFlow(unittest.TestCase):
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

    def test_full_auth_and_task_flow(self):
        client_response = self.client.post(
            "/users/register",
            json={
                "name": "Alice Client",
                "email": "alice@taskly.com",
                "password": "secure123",
                "role": "client",
                "phone": "0711111111",
            },
        )
        self.assertEqual(client_response.status_code, 201)
        client_id = client_response.json()["user_id"]

        tasker_response = self.client.post(
            "/users/register",
            json={
                "name": "Bob Tasker",
                "email": "bob@taskly.com",
                "password": "secure456",
                "role": "tasker",
                "phone": "0722222222",
            },
        )
        self.assertEqual(tasker_response.status_code, 201)
        tasker_id = tasker_response.json()["user_id"]

        login_response = self.client.post(
            "/users/login",
            data={"username": "alice@taskly.com", "password": "secure123"},
        )
        self.assertEqual(login_response.status_code, 200)
        client_token = login_response.json()["access_token"]

        me_response = self.client.get(
            "/users/me",
            headers={"Authorization": f"Bearer {client_token}"},
        )
        self.assertEqual(me_response.status_code, 200)
        self.assertEqual(me_response.json()["email"], "alice@taskly.com")

        task_response = self.client.post(
            f"/tasks/?client_id={client_id}",
            json={
                "title": "Clean my apartment",
                "description": "Deep clean 2-bedroom apartment",
                "price": 3000,
                "location": "Kilimani",
            },
        )
        self.assertEqual(task_response.status_code, 200)
        task_id = task_response.json()["id"]

        claim_response = self.client.post(f"/tasks/{task_id}/claim?tasker_id={tasker_id}")
        self.assertEqual(claim_response.status_code, 200)

        complete_response = self.client.post(f"/tasks/{task_id}/complete")
        self.assertEqual(complete_response.status_code, 200)

        review_response = self.client.post(
            "/reviews/",
            json={"rating": 5, "comment": "Excellent service!", "task_id": task_id},
            headers={"Authorization": f"Bearer {client_token}"},
        )
        self.assertEqual(review_response.status_code, 201)

        task_reviews = self.client.get(f"/reviews/task/{task_id}")
        self.assertEqual(task_reviews.status_code, 200)
        self.assertGreaterEqual(len(task_reviews.json()), 1)

    @classmethod
    def tearDownClass(cls):
        cls.engine.dispose()

if __name__ == "__main__":
    unittest.main()
