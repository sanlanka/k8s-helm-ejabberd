# Comprehensive Presence and Status Tests
# Test all presence states, status messages, and presence-related functionality

# Set various presence states
POST {{base_url}}/api/set_presence
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "user": "testuser",
  "host": "{{domain}}",
  "resource": "desktop",
  "type": "available",
  "show": "chat",
  "status": "Available for chat",
  "priority": "10"
}
HTTP 200

# Set DND (Do Not Disturb) presence
POST {{base_url}}/api/set_presence
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "user": "testuser",
  "host": "{{domain}}",
  "resource": "mobile",
  "type": "available",
  "show": "dnd",
  "status": "In a meeting - DND",
  "priority": "5"
}
HTTP 200

# Set Away presence
POST {{base_url}}/api/set_presence
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "user": "testuser",
  "host": "{{domain}}",
  "resource": "laptop",
  "type": "available",
  "show": "away",
  "status": "Away from keyboard",
  "priority": "1"
}
HTTP 200

# Set Extended Away (XA) presence
POST {{base_url}}/api/set_presence
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "user": "testuser",
  "host": "{{domain}}",
  "resource": "tablet",
  "type": "available",
  "show": "xa",
  "status": "Extended away - will be back later",
  "priority": "0"
}
HTTP 200

# Set Unavailable/Offline presence
POST {{base_url}}/api/set_presence
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "user": "testuser",
  "host": "{{domain}}",
  "resource": "work",
  "type": "unavailable",
  "show": "",
  "status": "Gone offline",
  "priority": "0"
}
HTTP 200

# Get user presence information
GET {{base_url}}/api/get_presence/testuser@{{domain}}
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$.show" exists
jsonpath "$.status" exists

# Get detailed session info for all user resources
GET {{base_url}}/api/user_sessions_info/testuser@{{domain}}
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$" isCollection
jsonpath "$[*].status" exists
jsonpath "$[*].resource" exists
jsonpath "$[*].priority" exists

# Get user's connected resources
GET {{base_url}}/api/user_resources/testuser@{{domain}}
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$" isCollection

# Get number of users with specific status
GET {{base_url}}/api/status_num_host/{{domain}}/dnd
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$.value" isInteger

# Get number of users with chat status
GET {{base_url}}/api/status_num_host/{{domain}}/chat
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$.value" isInteger

# Get number of away users
GET {{base_url}}/api/status_num_host/{{domain}}/away
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$.value" isInteger

# Get list of users with specific status
GET {{base_url}}/api/status_list_host/{{domain}}/available
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$" isCollection

# Get total connected users for host
GET {{base_url}}/api/connected_users_vhost/{{domain}}
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$" isCollection

# Get connected users number
GET {{base_url}}/api/connected_users_number
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$.value" isInteger

# Get detailed info about all connected users
GET {{base_url}}/api/connected_users_info
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$" isCollection

# Test presence subscription (roster-based)
POST {{base_url}}/api/add_rosteritem
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "localuser": "testuser",
  "localserver": "{{domain}}",
  "user": "friend",
  "server": "{{domain}}",
  "nick": "Friend User",
  "group": "friends",
  "subs": "both"
}
HTTP 200

# Send presence probe to check friend's presence
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "testuser@{{domain}}",
  "to": "friend@{{domain}}",
  "stanza": "<presence type='probe'/>"
}
HTTP 200

# Test typing indicators (composing state)
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "testuser@{{domain}}",
  "to": "friend@{{domain}}",
  "stanza": "<message type='chat'><composing xmlns='http://jabber.org/protocol/chatstates'/></message>"
}
HTTP 200

# Test paused typing state
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "testuser@{{domain}}",
  "to": "friend@{{domain}}",
  "stanza": "<message type='chat'><paused xmlns='http://jabber.org/protocol/chatstates'/></message>"
}
HTTP 200

# Test active chat state
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "testuser@{{domain}}",
  "to": "friend@{{domain}}",
  "stanza": "<message type='chat'><active xmlns='http://jabber.org/protocol/chatstates'/></message>"
}
HTTP 200

# Test inactive chat state
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "testuser@{{domain}}",
  "to": "friend@{{domain}}",
  "stanza": "<message type='chat'><inactive xmlns='http://jabber.org/protocol/chatstates'/></message>"
}
HTTP 200

# Test gone chat state (user left conversation)
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "testuser@{{domain}}",
  "to": "friend@{{domain}}",
  "stanza": "<message type='chat'><gone xmlns='http://jabber.org/protocol/chatstates'/></message>"
}
HTTP 200

# Get number of user resources
GET {{base_url}}/api/num_resources/testuser@{{domain}}
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$.value" isInteger

# Test kicking a specific session
POST {{base_url}}/api/kick_session
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "user": "testuser",
  "host": "{{domain}}",
  "resource": "tablet",
  "reason": "Testing session management"
}
HTTP 200 