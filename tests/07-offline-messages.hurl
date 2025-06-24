# Offline Messages and Last Activity Tests
# Test offline message storage, delivery, and last activity tracking

# Send message to offline user
POST {{base_url}}/api/send_message
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "type": "chat",
  "from": "testuser@{{domain}}",
  "to": "offlineuser@{{domain}}",
  "subject": "Offline Message Test",
  "body": "This message should be stored offline"
}
HTTP 200

# Send multiple offline messages
POST {{base_url}}/api/send_message
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "type": "chat",
  "from": "testuser@{{domain}}",
  "to": "offlineuser@{{domain}}",
  "subject": "Urgent",
  "body": "This is an urgent message that should be delivered when user comes online"
}
HTTP 200

POST {{base_url}}/api/send_message
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "type": "chat",
  "from": "friend@{{domain}}",
  "to": "offlineuser@{{domain}}",
  "subject": "Hello",
  "body": "Hello! Hope you're doing well. Message from friend."
}
HTTP 200

# Check offline message count
GET {{base_url}}/api/get_offline_count/offlineuser@{{domain}}
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$.value" isInteger
jsonpath "$.value" > 0

# Test last activity functionality
POST {{base_url}}/api/set_last
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "user": "testuser",
  "host": "{{domain}}",
  "timestamp": "1640995200",
  "status": "Away from keyboard"
}
HTTP 200

# Get user's last activity
GET {{base_url}}/api/get_last/testuser@{{domain}}
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$.last" exists
jsonpath "$.status" exists

# Delete old offline messages (cleanup)
POST {{base_url}}/api/delete_old_messages
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "host": "{{domain}}",
  "days": "30"
}
HTTP 200

# Get offline message deletion status
GET {{base_url}}/api/delete_old_messages_status/{{domain}}
Authorization: Bearer {{access_token}}
HTTP 200

# Test message expiration (delete expired messages)
POST {{base_url}}/api/delete_expired_messages
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "host": "{{domain}}"
}
HTTP 200

# Simulate user coming online to receive offline messages
POST {{base_url}}/api/set_presence
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "user": "offlineuser",
  "host": "{{domain}}",
  "resource": "mobile",
  "type": "available",
  "show": "chat",
  "status": "Just came online",
  "priority": "5"
}
HTTP 200

# Check offline count after user comes online (should be 0 if delivered)
GET {{base_url}}/api/get_offline_count/offlineuser@{{domain}}
Authorization: Bearer {{access_token}}
HTTP 200

# Test offline message with priority
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "testuser@{{domain}}",
  "to": "offlineuser2@{{domain}}",
  "stanza": "<message type='chat'><body>High priority offline message</body><priority>high</priority></message>"
}
HTTP 200 