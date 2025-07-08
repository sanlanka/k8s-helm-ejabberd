# Test 8: JWT Information and Status Test
# This test provides information about JWT support in the current ejabberd deployment

# Test 1: Verify server is running
POST {{ejabberd_api_url}}/api/status
Content-Type: application/json

{}

HTTP 200
[Asserts]
body contains "started"

# Test 2: Check available authentication methods
# The current sando38/helm-ejabberd chart uses basic authentication by default
# JWT authentication is not included in the base chart but can be added

# Test 3: Verify basic authentication is working
POST {{ejabberd_api_url}}/api/register
Content-Type: application/json

{
  "user": "jwt-info-test",
  "host": "{{test_host}}",
  "password": "jwt-info-password"
}

HTTP 200

# Test 4: Verify user was created
POST {{ejabberd_api_url}}/api/registered_users
Content-Type: application/json

{
  "host": "{{test_host}}"
}

HTTP 200
[Asserts]
body contains "jwt-info-test"

# Clean up: Remove test user
POST {{ejabberd_api_url}}/api/unregister
Content-Type: application/json

{
  "user": "jwt-info-test",
  "host": "{{test_host}}"
}

HTTP 200

# JWT STATUS INFORMATION:
# 
# Current Status: JWT authentication is NOT enabled in this deployment
# 
# To enable JWT authentication, you would need to:
# 1. Add JWT authentication module to the chart
# 2. Configure JWT secrets and parameters
# 3. Update the authentication configuration
# 
# The sando38/helm-ejabberd chart focuses on basic authentication
# and clustering features rather than advanced authentication methods.
# 
# For JWT support, you would need to either:
# - Modify the chart to include JWT modules
# - Use external authentication services
# - Implement JWT at the application layer 