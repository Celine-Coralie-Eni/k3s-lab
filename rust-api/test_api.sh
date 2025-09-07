#!/bin/bash

# Test script for K3s Lab Rust API
# Make sure the API is running on localhost:8080

BASE_URL="http://localhost:8080"
API_URL="$BASE_URL/api"

echo "🧪 Testing K3s Lab Rust API"
echo "=========================="

# Test health endpoint
echo -e "\n1. Testing health endpoint..."
curl -s "$BASE_URL/health" | jq '.'

# Test user registration
echo -e "\n2. Testing user registration..."
REGISTER_RESPONSE=$(curl -s -X POST "$API_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "testpassword123"
  }')

echo "$REGISTER_RESPONSE" | jq '.'

# Extract token from registration response
TOKEN=$(echo "$REGISTER_RESPONSE" | jq -r '.token')

if [ "$TOKEN" = "null" ] || [ "$TOKEN" = "" ]; then
    echo "❌ Failed to get token from registration"
    exit 1
fi

echo -e "\n✅ Registration successful, token: ${TOKEN:0:20}..."

# Test user login
echo -e "\n3. Testing user login..."
LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "testpassword123"
  }')

echo "$LOGIN_RESPONSE" | jq '.'

# Test creating a task
echo -e "\n4. Testing task creation..."
TASK_RESPONSE=$(curl -s -X POST "$API_URL/tasks" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Test Task",
    "description": "This is a test task for the API"
  }')

echo "$TASK_RESPONSE" | jq '.'

# Extract task ID
TASK_ID=$(echo "$TASK_RESPONSE" | jq -r '.task.id')

if [ "$TASK_ID" = "null" ] || [ "$TASK_ID" = "" ]; then
    echo "❌ Failed to get task ID"
    exit 1
fi

echo -e "\n✅ Task created with ID: $TASK_ID"

# Test getting all tasks
echo -e "\n5. Testing get all tasks..."
curl -s -X GET "$API_URL/tasks" \
  -H "Authorization: Bearer $TOKEN" | jq '.'

# Test getting specific task
echo -e "\n6. Testing get specific task..."
curl -s -X GET "$API_URL/tasks/$TASK_ID" \
  -H "Authorization: Bearer $TOKEN" | jq '.'

# Test updating task
echo -e "\n7. Testing task update..."
curl -s -X PUT "$API_URL/tasks/$TASK_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "title": "Updated Test Task",
    "description": "This task has been updated",
    "completed": true
  }' | jq '.'

# Test getting updated task
echo -e "\n8. Testing get updated task..."
curl -s -X GET "$API_URL/tasks/$TASK_ID" \
  -H "Authorization: Bearer $TOKEN" | jq '.'

# Test getting user profile
echo -e "\n9. Testing get user profile..."
curl -s -X GET "$API_URL/users" \
  -H "Authorization: Bearer $TOKEN" | jq '.'

echo -e "\n✅ All tests completed successfully!"
echo -e "\n🎉 The Rust API is working correctly!"


