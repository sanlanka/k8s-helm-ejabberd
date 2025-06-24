# User Management Tests
# Test user registration, authentication, and basic operations

# Register a new user
POST {{base_url}}/api/register
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "user": "newuser",
  "host": "{{domain}}",
  "password": "newpassword123"
}
HTTP 200
[Asserts]
jsonpath "$.status" == "success"

# Check if user exists
GET {{base_url}}/api/check_account/newuser@{{domain}}
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$.status" == "exists"

# Test user authentication with internal auth
POST {{base_url}}/api/check_password
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "user": "newuser",
  "host": "{{domain}}",
  "password": "newpassword123"
}
HTTP 200
[Asserts]
jsonpath "$.status" == "success"

# Get user roster
GET {{base_url}}/api/get_roster/newuser@{{domain}}
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$" isCollection

# Add user to roster
POST {{base_url}}/api/add_rosteritem
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "localuser": "newuser",
  "localserver": "{{domain}}",
  "user": "testuser",
  "server": "{{domain}}",
  "nick": "Test User",
  "group": "friends",
  "subs": "both"
}
HTTP 200

# Verify roster addition
GET {{base_url}}/api/get_roster/newuser@{{domain}}
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$[*].jid" includes "testuser@{{domain}}"

# Get user sessions
GET {{base_url}}/api/user_sessions_info/newuser@{{domain}}
Authorization: Bearer {{access_token}}
HTTP 200

# Delete test user (cleanup)
POST {{base_url}}/api/unregister
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "user": "newuser",
  "host": "{{domain}}"
}
HTTP 200 