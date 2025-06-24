# Test JWT Authentication with Firebase Tokens
# This test validates that ejabberd can authenticate users using Firebase JWT tokens

# Test 1: Health check before authentication
GET {{base_url}}/api/status
Content-Type: application/json
Authorization: Basic {{admin_auth}}

HTTP/1.1 200
[Asserts]
jsonpath "$.status" == "ok"

---

# Test 2: Validate JWT authentication is enabled
GET {{base_url}}/api/registered_users
Content-Type: application/json
Authorization: Basic {{admin_auth}}

HTTP/1.1 200
[Asserts]
jsonpath "$.users" != null

---

# Test 3: Test Firebase JWT token authentication
# This simulates a middleware sending a Firebase JWT token
POST {{base_url}}/api/auth_token
Content-Type: application/json
Authorization: Basic {{admin_auth}}

{
  "user": "firebase_user@{{domain}}",
  "server": "{{domain}}",
  "token": "{{firebase_jwt_token}}"
}

HTTP/1.1 200
[Asserts]
jsonpath "$.token" != null
jsonpath "$.token" != ""

---

# Test 4: Test XMPP authentication with JWT token
# This simulates an XMPP client authenticating with the JWT token
POST {{base_url}}/api/register
Content-Type: application/json
Authorization: Basic {{admin_auth}}

{
  "user": "firebase_user",
  "host": "{{domain}}",
  "password": "{{firebase_jwt_token}}"
}

HTTP/1.1 200
[Asserts]
jsonpath "$.res" == 0

---

# Test 5: Verify user was created via JWT authentication
GET {{base_url}}/api/registered_users
Content-Type: application/json
Authorization: Basic {{admin_auth}}

HTTP/1.1 200
[Asserts]
jsonpath "$.users" contains "firebase_user@{{domain}}"

---

# Test 6: Test XMPP SASL authentication with JWT
# This simulates the actual XMPP authentication flow
POST {{base_url}}/api/check_password
Content-Type: application/json
Authorization: Basic {{admin_auth}}

{
  "user": "firebase_user",
  "host": "{{domain}}",
  "password": "{{firebase_jwt_token}}"
}

HTTP/1.1 200
[Asserts]
jsonpath "$.res" == 0

---

# Test 7: Test JWT token validation with invalid token
POST {{base_url}}/api/auth_token
Content-Type: application/json
Authorization: Basic {{admin_auth}}

{
  "user": "invalid_user@{{domain}}",
  "server": "{{domain}}",
  "token": "invalid.jwt.token"
}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" != null

---

# Test 8: Test JWT token with expired token
POST {{base_url}}/api/auth_token
Content-Type: application/json
Authorization: Basic {{admin_auth}}

{
  "user": "expired_user@{{domain}}",
  "server": "{{domain}}",
  "token": "{{expired_jwt_token}}"
}

HTTP/1.1 400
[Asserts]
jsonpath "$.error" != null

---

# Test 9: Test Firebase-specific JWT claims
# This validates that Firebase user_id, email, and name are properly mapped
POST {{base_url}}/api/register
Content-Type: application/json
Authorization: Basic {{admin_auth}}

{
  "user": "firebase_claims_user",
  "host": "{{domain}}",
  "password": "{{firebase_jwt_with_claims}}"
}

HTTP/1.1 200
[Asserts]
jsonpath "$.res" == 0

---

# Test 10: Verify Firebase user profile data
GET {{base_url}}/api/get_vcard
Content-Type: application/json
Authorization: Basic {{admin_auth}}

{
  "user": "firebase_claims_user",
  "host": "{{domain}}",
  "name": "FN"
}

HTTP/1.1 200
[Asserts]
jsonpath "$.content" != null 