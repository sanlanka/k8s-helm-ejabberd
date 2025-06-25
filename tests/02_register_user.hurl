# Test 2: Register a new user account
# This test creates a user account that will be used in subsequent tests

POST {{ejabberd_api_url}}/api/register
Content-Type: application/json

{
  "user": "{{test_user}}",
  "host": "{{test_host}}",
  "password": "{{test_password}}"
}

HTTP 200
[Asserts]
body contains "successfully registered" 