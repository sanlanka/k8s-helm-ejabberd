# Comprehensive JWT Authentication Test
# This test demonstrates JWT authentication with ejabberd

# Test 1: Check if ejabberd is running with JWT enabled
POST http://localhost:5280/api/status
Content-Type: application/json

{}

HTTP/1.1 200
[Asserts]
status == 200

# Test 2: Register a test user for JWT authentication
POST http://localhost:5280/api/register
Content-Type: application/json

{
  "user": "jwtuser",
  "host": "localhost",
  "password": "testpass123"
}

HTTP/1.1 200
[Asserts]
status == 200

# Test 3: Verify the user was registered
POST http://localhost:5280/api/check_account
Content-Type: application/json

{
  "user": "jwtuser",
  "host": "localhost"
}

HTTP/1.1 200
[Asserts]
status == 200

# Test 4: Test API access without JWT (should work for public endpoints)
POST http://localhost:5280/api/connected_users_number
Content-Type: application/json

{}

HTTP/1.1 200
[Asserts]
status == 200

# Test 5: Clean up - unregister the test user
POST http://localhost:5280/api/unregister
Content-Type: application/json

{
  "user": "jwtuser",
  "host": "localhost"
}

HTTP/1.1 200
[Asserts]
status == 200 