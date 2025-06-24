# Health Check Test
# Verify ejabberd server is running and basic endpoints are accessible

# Basic server status check
GET {{base_url}}/api/status
HTTP 200
[Asserts]
jsonpath "$" isString

# Test connected users endpoint
GET {{base_url}}/api/connected_users_number
HTTP 200
[Asserts]
jsonpath "$" isInteger
