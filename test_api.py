import requests

BASE = "http://127.0.0.1:8000"

# 1. Create a task
print("Creating task...")
task = {
    "title": "Fix my sink",
    "description": "Kitchen sink is leaking",
    "price": 1500,
    "location": "Westlands"
}
r = requests.post(f"{BASE}/tasks/?client_id=1", json=task)
print(r.json())

# 2. Get all tasks
print("\nGetting all tasks...")
r = requests.get(f"{BASE}/tasks/")
print(r.json())

# 3. Claim task
print("\nClaiming task...")
r = requests.post(f"{BASE}/tasks/1/claim?tasker_id=2")
print(r.json())

# 4. Complete task
print("\nCompleting task...")
r = requests.post(f"{BASE}/tasks/1/complete")
print(r.json())