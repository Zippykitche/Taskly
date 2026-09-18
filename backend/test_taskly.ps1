# Test Taskly Full Flow

# Test 1: Recruiter Register
Write-Host "TEST 1: Recruiter Registration" -ForegroundColor Green
$recruiter_reg = curl.exe -X POST http://localhost:8003/auth/register `
  -H "Content-Type: application/json" `
  -d "@register_recruiter.json"

Write-Host $recruiter_reg
Write-Host ""

# Test 2: Recruiter Login
Write-Host "TEST 2: Recruiter Login" -ForegroundColor Green
$recruiter_login = curl.exe -X POST http://localhost:8003/auth/login `
  -H "Content-Type: application/x-www-form-urlencoded" `
  -d "username=254712345678&password=password123"

Write-Host $recruiter_login
Write-Host ""

# Test 3: Tasker Register
Write-Host "TEST 3: Tasker Registration" -ForegroundColor Green
$tasker_reg = curl.exe -X POST http://localhost:8002/auth/register `
  -H "Content-Type: application/json" `
  -d "@register_tasker.json"

Write-Host $tasker_reg
Write-Host ""

# Test 4: Tasker Login
Write-Host "TEST 4: Tasker Login" -ForegroundColor Green
$tasker_login = curl.exe -X POST http://localhost:8002/auth/login `
  -H "Content-Type: application/x-www-form-urlencoded" `
  -d "username=254708374149&password=password123"

Write-Host $tasker_login
Write-Host ""

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "Copy the access_token from above and replace in next tests!" -ForegroundColor Yellow
Write-Host "====================================" -ForegroundColor Cyan

# Test 5: Browse Jobs (Tasker)
Write-Host "TEST 5: Browse Jobs" -ForegroundColor Green
$browse_jobs = curl.exe -X GET http://localhost:8002/jobs/browse `
  -H "Authorization: Bearer YOUR_TOKEN"

Write-Host $browse_jobs
Write-Host ""

# Test 6: Recommended Jobs (Tasker)
Write-Host "TEST 6: Recommended Jobs" -ForegroundColor Green
$rec_jobs = curl.exe -X GET http://localhost:8002/jobs/recommended `
  -H "Authorization: Bearer YOUR_TOKEN"

Write-Host $rec_jobs
Write-Host ""
