# Health Check Test
# Verify ejabberd server is running and basic endpoints are accessible

# Basic server status check
GET {{base_url}}/api/status
HTTP 200
[Asserts]
jsonpath "$" isString

# Check if admin interface is accessible (should return HTML)
GET {{base_url}}/admin/
HTTP 200

# Test another basic endpoint
GET {{base_url}}/api/connected_users_number
HTTP 200 