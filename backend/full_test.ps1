# ==========================================
# TASKLY COMPLETE E2E TEST - WEEK 1
# ==========================================

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "TASKLY COMPLETE TEST - WEEK 1" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Phase 1: Register Recruiter
Write-Host "1️⃣ Register Recruiter..." -ForegroundColor Green
curl.exe -s -X POST http://localhost:8003/auth/register -H "Content-Type: application/json" -d '{"phone_number":"254712345678","password":"password123","full_name":"John Recruiter","email":"recruiter@test.com","location_city":"Nairobi","location_area":"Westlands"}'
Write-Host ""

# Phase 2: Register Tasker
Write-Host "2️⃣ Register Tasker..." -ForegroundColor Green
curl.exe -s -X POST http://localhost:8002/auth/register -H "Content-Type: application/json" -d '{"phone_number":"254708374149","password":"password123","full_name":"Alice Plumber","email":"tasker@test.com","id_number":"12345678","categories":["Plumbing","Electrical"],"location_city":"Nairobi","location_area":"Embakasi"}'
Write-Host ""

# Phase 3: Recruiter Login
Write-Host "3️⃣ Recruiter Login..." -ForegroundColor Green
$r_login = curl.exe -s -X POST http://localhost:8003/auth/login -H "Content-Type: application/x-www-form-urlencoded" -d "username=254712345678&password=password123"
Write-Host $r_login
$recruiter_token = ($r_login | ConvertFrom-Json).access_token
Write-Host "Token: $($recruiter_token.Substring(0,30))..." -ForegroundColor Green
Write-Host ""

# Phase 4: Tasker Login
Write-Host "4️⃣ Tasker Login..." -ForegroundColor Green
$t_login = curl.exe -s -X POST http://localhost:8002/auth/login -H "Content-Type: application/x-www-form-urlencoded" -d "username=254708374149&password=password123"
Write-Host $t_login
$tasker_token = ($t_login | ConvertFrom-Json).access_token
Write-Host "Token: $($tasker_token.Substring(0,30))..." -ForegroundColor Green
Write-Host ""

# Phase 5: Create Job
Write-Host "5️⃣ Create Job..." -ForegroundColor Green
curl.exe -s -X POST http://localhost:8003/jobs/create -H "Authorization: Bearer $recruiter_token" -H "Content-Type: application/json" -d '{"title":"Fix Leaking Sink","description":"Water pooling under sink","category":"Plumbing","location_city":"Nairobi","location_area":"Westlands","location_address":"100 Main Street","urgency":"urgent"}'
Write-Host ""

# Phase 6: Browse Jobs
Write-Host "6️⃣ Browse Jobs..." -ForegroundColor Green
curl.exe -s http://localhost:8002/jobs/browse -H "Authorization: Bearer $tasker_token"
Write-Host ""

# Phase 7: Get Recommendations
Write-Host "7️⃣ Get Recommendations..." -ForegroundColor Green
curl.exe -s http://localhost:8002/jobs/recommended -H "Authorization: Bearer $tasker_token"
Write-Host ""

# Phase 8: Apply for Job
Write-Host "8️⃣ Apply for Job..." -ForegroundColor Green
curl.exe -s -X POST http://localhost:8002/jobs/1/apply -H "Authorization: Bearer $tasker_token" -H "Content-Type: application/json" -d '{"job_id":1,"cover_letter":"Im experienced"}'
Write-Host ""

# Phase 9: View Applications
Write-Host "9️⃣ View Applications..." -ForegroundColor Green
curl.exe -s http://localhost:8003/jobs/1/applications -H "Authorization: Bearer $recruiter_token"
Write-Host ""

# Phase 10: Get Profile
Write-Host "🔟 Get Profile..." -ForegroundColor Green
curl.exe -s http://localhost:8002/profile/me -H "Authorization: Bearer $tasker_token"
Write-Host ""

# Phase 11: Get Wallet
Write-Host "1️⃣1️⃣ Get Wallet..." -ForegroundColor Green
curl.exe -s http://localhost:8002/earnings/wallet -H "Authorization: Bearer $tasker_token"
Write-Host ""

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "✅ TEST COMPLETE!" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
