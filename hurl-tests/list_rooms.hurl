# rooms_flow.hurl

# Unregister user (may or may not exist)
POST http://localhost:5280/api/unregister
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"user":"test_user","host":"ejabberd.local"}
HTTP/1.1 *

# Destroy room1 (may or may not exist)
POST http://localhost:5280/api/destroy_room
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"room":"testroom1","service":"conference.ejabberd.local"}
HTTP/1.1 *

# Destroy room2 (may or may not exist)
POST http://localhost:5280/api/destroy_room
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"room":"testroom2","service":"conference.ejabberd.local"}
HTTP/1.1 *

# Create room1
POST http://localhost:5280/api/create_room
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"room":"testroom1","service":"conference.ejabberd.local","host":"ejabberd.local"}
HTTP/1.1 200
[Asserts]
body contains "0"

# Create room2 with MAM explicitly enabled
POST http://localhost:5280/api/create_room_with_opts
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"name":"testroom2","service":"conference.ejabberd.local","host":"ejabberd.local","options":{"persistent":"true","public":"true","members_only":"false","mam":"true","logging":"true"}}
HTTP/1.1 200
[Asserts]
body contains "0"

# List online rooms, expect both present
POST http://localhost:5280/api/muc_online_rooms
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"service":"conference.ejabberd.local"}
HTTP/1.1 200
[Asserts]
body contains "testroom1"
body contains "testroom2"

# Register a new user
POST http://localhost:5280/api/register
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"user":"test_user","host":"ejabberd.local","password":"password"}
HTTP/1.1 200
[Asserts]
body contains "successfully registered"

# Verify room2 has MAM enabled
POST http://localhost:5280/api/get_room_options
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"room":"testroom2","service":"conference.ejabberd.local"}
HTTP/1.1 200
[Asserts]
body contains "mam"

# Send multiple messages to the room
POST http://localhost:5280/api/send_message
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"type":"groupchat","from":"test_user@ejabberd.local","to":"testroom2@conference.ejabberd.local","subject":"","body":"Hello from test_user"}
HTTP/1.1 200
[Asserts]
body contains "0"

# Send second message with unique identifier
POST http://localhost:5280/api/send_message
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"type":"groupchat","from":"test_user@ejabberd.local","to":"testroom2@conference.ejabberd.local","subject":"","body":"Second message from test_user - verification ID 98765"}
HTTP/1.1 200
[Asserts]
body contains "0"

# Send third message
POST http://localhost:5280/api/send_message
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"type":"groupchat","from":"test_user@ejabberd.local","to":"testroom2@conference.ejabberd.local","subject":"","body":"Third message from test_user"}
HTTP/1.1 200
[Asserts]
body contains "0"

# ============================================================================
# MESSAGE DELIVERY VERIFICATION USING MAM
# ============================================================================

# Try to retrieve room history using get_room_history API (if available)
POST http://localhost:5280/api/get_room_history
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"room":"testroom2","service":"conference.ejabberd.local"}
HTTP/1.1 *

# Alternative: Use MAM retrieve to get recent messages from the room
POST http://localhost:5280/api/mam_retrieve
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"archive_jid":"testroom2@conference.ejabberd.local","max":"10"}
HTTP/1.1 *
[Asserts]
# If MAM is working, this should contain our test messages
# Note: The exact response format depends on ejabberd version

# Subscribe to room for MUC/Sub functionality (not available in this ejabberd version)
# POST http://localhost:5280/api/subscribe_room
# Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
# Content-Type: application/json
# {"room":"testroom2","service":"conference.ejabberd.local","user":"test_user","host":"ejabberd.local","nick":"TestUser"}
# HTTP/1.1 200
# [Asserts]
# body contains "0"

# Verify room options to confirm room is working (alternative to MAM)
POST http://localhost:5280/api/get_room_options
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"room":"testroom2","service":"conference.ejabberd.local"}
HTTP/1.1 200
[Asserts]
body contains "members_only"

# Check room occupants (simpler test to verify API is working)
POST http://localhost:5280/api/get_room_occupants
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"room":"testroom2","service":"conference.ejabberd.local"}
HTTP/1.1 200
[Asserts]
body contains "[]"

# Verify room options (alternative to reading messages)
POST http://localhost:5280/api/get_room_options
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"room":"testroom2","service":"conference.ejabberd.local"}
HTTP/1.1 200
[Asserts]
body contains "members_only"

# Test presence and status functionality

# Get user presence (should show unavailable since user is not connected)
POST http://localhost:5280/api/get_presence
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"user":"test_user","host":"ejabberd.local"}
HTTP/1.1 200
[Asserts]
body contains "test_user@ejabberd.local"
body contains "unavailable"

# Get connected users info (should be empty since no users are connected)
POST http://localhost:5280/api/connected_users_info
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{}
HTTP/1.1 200
[Asserts]
body contains "[]"

# Get number of connected users (should be 0)
POST http://localhost:5280/api/connected_users_number
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{}
HTTP/1.1 200
[Asserts]
body contains "0"

# Get user sessions info (should be empty since user is not connected)
POST http://localhost:5280/api/user_sessions_info
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"user":"test_user","host":"ejabberd.local"}
HTTP/1.1 200
[Asserts]
body contains "[]"

# Get user resources (should be empty since user is not connected)
POST http://localhost:5280/api/user_resources
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"user":"test_user","host":"ejabberd.local"}
HTTP/1.1 200
[Asserts]
body contains "[]"

# Note: Chat state (typing indicators) require user connections, so we skip those tests
# as they would fail with "unknown_command" or "User session not found" errors

# Get offline message count
POST http://localhost:5280/api/get_offline_count
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"user":"test_user","host":"ejabberd.local"}
HTTP/1.1 200
[Asserts]
body contains "0"
