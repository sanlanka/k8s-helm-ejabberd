# Test 5: Verify that the user account no longer exists
# This test confirms that the user was successfully removed

POST {{ejabberd_api_url}}/api/registered_users
Content-Type: application/json

{
  "host": "{{test_host}}"
}

HTTP 200
[Asserts]
jsonpath "$" not contains "{{test_user}}" 