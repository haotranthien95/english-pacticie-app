#!/bin/bash
# Test script for register API endpoint

BASE_URL="http://localhost:8000/api/v1"

echo "========================================="
echo "Testing Register API Endpoint"
echo "========================================="

# Test 1: Successful Registration
echo -e "\n[Test 1] Successful Registration"
curl -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@example.com",
    "name": "Test User",
    "password": "SecurePass123!"
  }' \
  -w "\nHTTP Status: %{http_code}\n" \
  -s | jq '.'

# Test 2: Duplicate Email
echo -e "\n[Test 2] Duplicate Email (Should fail)"
curl -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@example.com",
    "name": "Another User",
    "password": "AnotherPass123!"
  }' \
  -w "\nHTTP Status: %{http_code}\n" \
  -s | jq '.'

# Test 3: Weak Password
echo -e "\n[Test 3] Weak Password (Should fail)"
curl -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newuser@example.com",
    "name": "New User",
    "password": "weak"
  }' \
  -w "\nHTTP Status: %{http_code}\n" \
  -s | jq '.'

# Test 4: Missing Required Fields
echo -e "\n[Test 4] Missing Required Fields (Should fail)"
curl -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "incomplete@example.com"
  }' \
  -w "\nHTTP Status: %{http_code}\n" \
  -s | jq '.'

# Test 5: Invalid Email Format
echo -e "\n[Test 5] Invalid Email Format (Should fail)"
curl -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "invalid-email",
    "name": "Invalid Email User",
    "password": "ValidPass123!"
  }' \
  -w "\nHTTP Status: %{http_code}\n" \
  -s | jq '.'

echo -e "\n========================================="
echo "Tests Completed"
echo "========================================="
