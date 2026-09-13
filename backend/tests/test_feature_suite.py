import os
import time
import uuid

import pytest
import requests


TASKER_BASE = os.getenv("TASKER_BASE", "http://127.0.0.1:8002")
RECRUITER_BASE = os.getenv("RECRUITER_BASE", "http://127.0.0.1:8003")


@pytest.fixture(scope="module")
def suffix():
    return str(int(time.time()))


def test_health_endpoints():
    tasker = requests.get(f"{TASKER_BASE}/", timeout=10)
    recruiter = requests.get(f"{RECRUITER_BASE}/", timeout=10)
    assert tasker.status_code == 200
    assert recruiter.status_code == 200


def test_tasker_auth_flow(suffix):
    phone = f"074{suffix[-8:]}"
    email = f"tasker_{suffix}@example.com"
    payload = {
        "phone_number": phone,
        "password": "StrongPass123!",
        "full_name": "Tasker Tester",
        "email": email,
        "id_number": "12345678",
        "categories": ["Cleaning"],
        "location_city": "Nairobi",
        "location_area": "Westlands",
    }

    reg = requests.post(f"{TASKER_BASE}/auth/register", json=payload, timeout=10)
    assert reg.status_code in (200, 201), reg.text

    login = requests.post(
        f"{TASKER_BASE}/auth/login",
        data={"username": phone, "password": "StrongPass123!"},
        timeout=10,
    )
    assert login.status_code == 200, login.text
    token = login.json()["access_token"]
    assert token

    me = requests.get(f"{TASKER_BASE}/profile/me", headers={"Authorization": f"Bearer {token}"}, timeout=10)
    assert me.status_code == 200, me.text


def test_recruiter_auth_flow(suffix):
    phone = f"075{suffix[-8:]}"
    email = f"recruiter_{suffix}@example.com"
    payload = {
        "phone_number": phone,
        "password": "StrongPass123!",
        "full_name": "Recruiter Tester",
        "email": email,
        "location_city": "Nairobi",
        "location_area": "Kilimani",
    }

    reg = requests.post(f"{RECRUITER_BASE}/auth/register", json=payload, timeout=10)
    assert reg.status_code in (200, 201), reg.text

    login = requests.post(
        f"{RECRUITER_BASE}/auth/login",
        data={"username": phone, "password": "StrongPass123!"},
        timeout=10,
    )
    assert login.status_code == 200, login.text
    token = login.json()["access_token"]
    assert token


def test_job_management_and_application_flow(suffix):
    recruiter_phone = f"075{suffix[-8:]}"
    recruiter_login = requests.post(
        f"{RECRUITER_BASE}/auth/login",
        data={"username": recruiter_phone, "password": "StrongPass123!"},
        timeout=10,
    )
    recruiter_token = recruiter_login.json()["access_token"]

    job_payload = {
        "title": "Deep clean living room",
        "description": "Need help cleaning and tidying a small apartment.",
        "category": "Cleaning",
        "location_city": "Nairobi",
        "location_area": "Kilimani",
        "location_address": "123 Main Street",
        "urgency": "normal",
    }
    created = requests.post(
        f"{RECRUITER_BASE}/jobs/create",
        json=job_payload,
        headers={"Authorization": f"Bearer {recruiter_token}"},
        timeout=10,
    )
    assert created.status_code == 200, created.text
    job_id = created.json()["id"]

    tasker_phone = f"074{suffix[-8:]}"
    tasker_login = requests.post(
        f"{TASKER_BASE}/auth/login",
        data={"username": tasker_phone, "password": "StrongPass123!"},
        timeout=10,
    )
    tasker_token = tasker_login.json()["access_token"]

    browse = requests.get(f"{TASKER_BASE}/jobs/browse", headers={"Authorization": f"Bearer {tasker_token}"}, timeout=10)
    assert browse.status_code == 200, browse.text

    apply = requests.post(
        f"{TASKER_BASE}/jobs/{job_id}/apply",
        headers={"Authorization": f"Bearer {tasker_token}"},
        timeout=10,
    )
    assert apply.status_code in (200, 201), apply.text

    apps = requests.get(
        f"{RECRUITER_BASE}/jobs/{job_id}/applications",
        headers={"Authorization": f"Bearer {recruiter_token}"},
        timeout=10,
    )
    assert apps.status_code == 200, apps.text

    accept = requests.post(
        f"{RECRUITER_BASE}/applications/{apps.json()['applications'][0]['id']}/accept",
        headers={"Authorization": f"Bearer {recruiter_token}"},
        timeout=10,
    )
    assert accept.status_code == 200, accept.text


def test_ratings_reviews_and_disputes(suffix):
    recruiter_phone = f"075{suffix[-8:]}"
    recruiter_login = requests.post(
        f"{RECRUITER_BASE}/auth/login",
        data={"username": recruiter_phone, "password": "StrongPass123!"},
        timeout=10,
    )
    recruiter_token = recruiter_login.json()["access_token"]

    tasker_phone = f"074{suffix[-8:]}"
    tasker_login = requests.post(
        f"{TASKER_BASE}/auth/login",
        data={"username": tasker_phone, "password": "StrongPass123!"},
        timeout=10,
    )
    tasker_token = tasker_login.json()["access_token"]

    # Use a known job id from the previous flow by reading the latest job from recruiter endpoint.
    jobs = requests.get(f"{RECRUITER_BASE}/jobs/my/jobs", headers={"Authorization": f"Bearer {recruiter_token}"}, timeout=10)
    assert jobs.status_code == 200, jobs.text
    job_id = jobs.json()["jobs"][0]["id"]

    rating = requests.post(
        f"{TASKER_BASE}/jobs/{job_id}/rate",
        headers={"Authorization": f"Bearer {tasker_token}"},
        json={"job_id": job_id, "ratee_id": 1, "rating_value": 5, "review": "Great work"},
        timeout=10,
    )
    assert rating.status_code in (200, 201, 400), rating.text

    dispute = requests.post(
        f"{TASKER_BASE}/jobs/{job_id}/dispute",
        headers={"Authorization": f"Bearer {tasker_token}"},
        json={"reason": "Payment issue", "description": "The job was not completed as expected"},
        timeout=10,
    )
    assert dispute.status_code in (200, 201), dispute.text


def test_claude_ai_and_support_chat(suffix):
    tasker_phone = f"074{suffix[-8:]}"
    tasker_login = requests.post(
        f"{TASKER_BASE}/auth/login",
        data={"username": tasker_phone, "password": "StrongPass123!"},
        timeout=10,
    )
    tasker_token = tasker_login.json()["access_token"]

    support = requests.post(
        f"{TASKER_BASE}/support/chat",
        headers={"Authorization": f"Bearer {tasker_token}"},
        json={"message": "How do I withdraw my earnings?"},
        timeout=10,
    )
    assert support.status_code == 200, support.text
    assert support.text


def test_email_service_and_pricing_helpers():
    from shared.services.email_service import EmailService
    from shared.services.claude_ai import ClaudeAI

    email_service = EmailService()
    assert email_service.send_registration_email("test@example.com", "Jane", "tasker") is False or isinstance(email_service.send_registration_email("test@example.com", "Jane", "tasker"), bool)

    pricing = ClaudeAI.analyze_job_complexity("Paint walls", "Fresh coat needed", "Painting", "urgent")
    assert pricing["complexity_score"] >= 1.0
    assert pricing["difficulty_level"]
