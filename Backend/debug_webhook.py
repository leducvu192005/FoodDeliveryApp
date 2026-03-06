"""
Script DEBUG webhook - Hiển thị TOÀN BỘ dữ liệu từ Sepay để tìm lỗi
Chạy để xem Sepay gửi gì đến backend
"""
import requests
import json

print("="*70)
print("🔍 DEBUG WEBHOOK - Test với data giả để verify logic")
print("="*70)
print()

# Test case 1: Format chuẩn (legacy test fields)
print("📝 Test 1: Legacy format (transaction_content + amount_in)")
response = requests.post(
    "http://localhost:8000/api/sepay/webhook",
    json={
        "transaction_content": "FD55 buyer",
        "amount_in": 20000
    }
)
print(f"   Status: {response.status_code}")
print(f"   Response: {response.json()}")
print()

# Test case 2: Real SePay format (content + transferAmount)
print("📝 Test 2: Real SePay format (content + transferAmount)")
response = requests.post(
    "http://localhost:8000/api/sepay/webhook",
    json={
        "id": 99999,
        "gateway": "MBBank",
        "transactionDate": "2026-03-07 10:00:00",
        "accountNumber": "088448888",
        "content": "FD55 buyer",
        "transferType": "in",
        "transferAmount": 20000,
        "referenceCode": "FT99999",
        "accumulated": 1000000
    }
)
print(f"   Status: {response.status_code}")
print(f"   Response: {response.json()}")
print()

# Test case 3: Bank-modified content (with prefix)
print("📝 Test 3: Bank-modified content (MBVCB prefix)")
response = requests.post(
    "http://localhost:8000/api/sepay/webhook",
    json={
        "content": "MBVCB.99999.FD55.CT tu 0123456789",
        "transferType": "in",
        "transferAmount": 20000
    }
)
print(f"   Status: {response.status_code}")
print(f"   Response: {response.json()}")
print()

# Test case 4: Lowercase fd
print("📝 Test 4: Lowercase fd55")
response = requests.post(
    "http://localhost:8000/api/sepay/webhook",
    json={
        "content": "fd55 buyer",
        "transferType": "in",
        "transferAmount": 20000
    }
)
print(f"   Status: {response.status_code}")
print(f"   Response: {response.json()}")
print()

# Test case 5: Outgoing transfer (should be ignored)
print("📝 Test 5: Outgoing transfer (should be ignored)")
response = requests.post(
    "http://localhost:8000/api/sepay/webhook",
    json={
        "content": "FD55 buyer",
        "transferType": "out",
        "transferAmount": 20000
    }
)
print(f"   Status: {response.status_code}")
print(f"   Response: {response.json()}")
print()

print("="*70)
print("✅ Test completed!")
print()
print("💡 Hướng dẫn debug:")
print("   1. Xem logs ở terminal đang chạy uvicorn")
print("   2. Mỗi webhook sẽ log TOÀN BỘ payload từ Sepay")
print("   3. So sánh payload thực với test cases trên")
print("="*70)
