import requests

BASE = "http://127.0.0.1:8000"

print("=== 1. REGISTER USERS ===")
# Register client
client_response = requests.post(f"{BASE}/users/register", json={
    "name": "Alice Client",
    "email": "alice@taskly.com",
    "password": "secure123",
    "role": "client",
    "phone": "0711111111"
})
print("Client registration:", client_response.json())

# Register tasker
tasker_response = requests.post(f"{BASE}/users/register", json={
    "name": "Bob Tasker",
    "email": "bob@taskly.com",
    "password": "secure456",
    "role": "tasker",
    "phone": "0722222222"
})
print("Tasker registration:", tasker_response.json())

print("\n=== 2. LOGIN ===")
# Login as client
login_response = requests.post(f"{BASE}/users/login", data={
    "username": "alice@taskly.com",
    "password": "secure123"
})
client_token = login_response.json()["access_token"]
print("Client login:", login_response.json())

# Login as tasker
tasker_login = requests.post(f"{BASE}/users/login", data={
    "username": "bob@taskly.com",
    "password": "secure456"
})
tasker_token = tasker_login.json()["access_token"]
print("Tasker login:", tasker_login.json())

print("\n=== 3. GET CURRENT USER ===")
me_response = requests.get(
    f"{BASE}/users/me",
    headers={"Authorization": f"Bearer {client_token}"}
)
print("Current user:", me_response.json())

print("\n=== 4. CREATE TASK (with auth) ===")
# Note: We still need to update tasks.py to use auth - doing that next
task_response = requests.post(
    f"{BASE}/tasks/?client_id={login_response.json()['user_id']}",
    json={
        "title": "Clean my apartment",
        "description": "Deep clean 2-bedroom apartment",
        "price": 3000,
        "location": "Kilimani"
    }
)
task_id = task_response.json()["id"]
print("Task created:", task_response.json())

print("\n=== 5. SEARCH TASKS ===")
# Search by location
search_response = requests.get(f"{BASE}/tasks/search?location=Kilimani")
print("Search results:", search_response.json())

# Search by price range
price_search = requests.get(f"{BASE}/tasks/search?min_price=2000&max_price=5000")
print("Price filter:", price_search.json())

print("\n=== 6. CLAIM TASK ===")
claim_response = requests.post(
    f"{BASE}/tasks/{task_id}/claim?tasker_id={tasker_login.json()['user_id']}"
)
print("Task claimed:", claim_response.json())

print("\n=== 7. COMPLETE TASK ===")
complete_response = requests.post(f"{BASE}/tasks/{task_id}/complete")
print("Task completed:", complete_response.json())

print("\n=== 8. CREATE REVIEW (with auth) ===")
review_response = requests.post(
    f"{BASE}/reviews/",
    json={
        "rating": 5,
        "comment": "Excellent service! Very professional and thorough.",
        "task_id": task_id
    },
    headers={"Authorization": f"Bearer {client_token}"}
)
print("Review created:", review_response.json())

print("\n=== 9. GET TASK REVIEWS ===")
task_reviews = requests.get(f"{BASE}/reviews/task/{task_id}")
print("Task reviews:", task_reviews.json())