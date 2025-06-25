# Test 3: Verify that the user account exists
# This test confirms that the user was successfully registered

POST {{ejabberd_api_url}}/api/registered_users
Content-Type: application/json

{
  "host": "{{test_host}}"
}

HTTP 200
[Asserts]
jsonpath "$" contains "{{test_user}}" 