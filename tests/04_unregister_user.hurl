# Test 4: Unregister (delete) the user account
# This test removes the user account that was created in test 2

POST {{ejabberd_api_url}}/api/unregister
Content-Type: application/json

{
  "user": "{{test_user}}",
  "host": "{{test_host}}"
}

HTTP 200 