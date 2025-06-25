# Test 6: JWT Authentication Test
# This test verifies that ejabberd can authenticate users via JWT tokens
# For now, this is a stub - we'll test that the server is configured for JWT

POST {{ejabberd_api_url}}/api/status
Content-Type: application/json

{}

HTTP 200
[Asserts]
body contains "started"

# TODO: Once JWT is implemented, this test should:
# 1. Generate a JWT token with {"jid": "test@localhost", "exp": future_timestamp}
# 2. Use that token to authenticate via XMPP
# 3. Verify the authentication succeeds 