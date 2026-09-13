import os
import time
import requests

TASKER_BASE = os.getenv('TASKER_BASE','http://127.0.0.1:8002')
RECRUITER_BASE = os.getenv('RECRUITER_BASE','http://127.0.0.1:8003')

suffix = str(int(time.time()))
print('HEALTH', requests.get(TASKER_BASE + '/', timeout=10).status_code, requests.get(RECRUITER_BASE + '/', timeout=10).status_code)

phone = f'074{suffix[-8:]}'
reg = requests.post(TASKER_BASE + '/auth/register', json={
    'phone_number': phone,
    'password': 'StrongPass123!',
    'full_name': 'Tasker Tester',
    'email': f'tasker_{suffix}@example.com',
    'id_number': '12345678',
    'categories': ['Cleaning'],
    'location_city': 'Nairobi',
    'location_area': 'Westlands',
}, timeout=10)
print('TASKER_REGISTER', reg.status_code, reg.text)
login = requests.post(TASKER_BASE + '/auth/login', data={'username': phone, 'password': 'StrongPass123!'}, timeout=10)
print('TASKER_LOGIN', login.status_code, login.text)
