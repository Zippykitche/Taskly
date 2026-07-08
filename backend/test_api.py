import requests
import time

BASE = "http://127.0.0.1:8000"
ts = int(time.time())

# 0. Setup Auth for testing
requests.post(f"{BASE}/users/register", json={
    "name": "Test User", "email": f"test_{ts}@api.com", "password": "password", "role": "tasker", "phone": "000"
})
login = requests.post(f"{BASE}/users/login", data={"username": f"test_{ts}@api.com", "password": "password"}).json()
headers = {"Authorization": f"Bearer {login['access_token']}"}

# 1. Create a task
print("Creating task...")
task = {
    "title": f"Fix sink {ts}",
    "description": "Kitchen sink is leaking",
    "price": 1500,
    "location": "Westlands"
}
r = requests.post(f"{BASE}/tasks/", json=task, headers=headers)
task_data = r.json()
print(task_data)

# 2. Get all tasks
print("\nGetting all tasks...")
r = requests.get(f"{BASE}/tasks/")
print(f"Found {len(r.json())} tasks")

# 3. Claim task
print("\nClaiming task...")
r = requests.post(f"{BASE}/tasks/{task_data['id']}/claim", headers=headers)
print(r.json())

# 4. Complete task
print("\nCompleting task...")
r = requests.post(f"{BASE}/tasks/{task_data['id']}/complete", headers=headers)
print(r.json())