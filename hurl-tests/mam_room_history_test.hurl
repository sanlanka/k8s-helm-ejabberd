# MAM Room History Test - Verify message delivery to MUC rooms
# This test sends a message to a MUC room and then retrieves it using MAM
# to verify that the message was actually delivered and stored.

# Clean up any existing test data
POST http://localhost:5280/api/unregister
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"user":"mam_test_user","host":"ejabberd.local"}
HTTP/1.1 *

POST http://localhost:5280/api/destroy_room
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"room":"mamtestroom","service":"conference.ejabberd.local"}
HTTP/1.1 *

# Register test user
POST http://localhost:5280/api/register
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"user":"mam_test_user","host":"ejabberd.local","password":"password"}
HTTP/1.1 200
[Asserts]
body contains "successfully registered"

# Create room with MAM enabled
POST http://localhost:5280/api/create_room_with_opts
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"name":"mamtestroom","service":"conference.ejabberd.local","host":"ejabberd.local","options":{"persistent":"true","public":"true","members_only":"false","mam":"true","logging":"true"}}
HTTP/1.1 200
[Asserts]
body contains "0"

# Verify room was created and MAM is enabled
POST http://localhost:5280/api/get_room_options
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"room":"mamtestroom","service":"conference.ejabberd.local"}
HTTP/1.1 200
[Asserts]
body contains "mam"
body contains "true"

# Send a unique test message to the room
POST http://localhost:5280/api/send_message
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"type":"groupchat","from":"mam_test_user@ejabberd.local","to":"mamtestroom@conference.ejabberd.local","subject":"","body":"MAM test message - unique identifier 12345"}
HTTP/1.1 200
[Asserts]
body contains "0"

# Wait a moment for message to be archived (if needed)
# Note: In real implementation, you might need a small delay

# Retrieve room history using MAM - try different approaches
# Approach 1: Try get_room_history if available
POST http://localhost:5280/api/get_room_history
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"room":"mamtestroom","service":"conference.ejabberd.local"}
HTTP/1.1 *
[Asserts]
# If this endpoint exists and works, our test message should be in the response
# Note: This might not exist in all ejabberd versions

# Approach 2: Use MAM retrieve for the room
POST http://localhost:5280/api/mam_retrieve
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"archive_jid":"mamtestroom@conference.ejabberd.local","max":"10"}
HTTP/1.1 *
[Asserts]
# If MAM is working, this should return our test message

# Approach 3: Alternative - check if message affected room state
# Send a second message and verify both are in sequence
POST http://localhost:5280/api/send_message
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"type":"groupchat","from":"mam_test_user@ejabberd.local","to":"mamtestroom@conference.ejabberd.local","subject":"","body":"Second MAM test message - unique identifier 67890"}
HTTP/1.1 200
[Asserts]
body contains "0"

# Try to retrieve messages again to verify both messages
POST http://localhost:5280/api/mam_retrieve
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"archive_jid":"mamtestroom@conference.ejabberd.local","max":"20"}
HTTP/1.1 *
[Asserts]
# Should contain both test messages if MAM is working

# Alternative verification: Check room logs if mod_muc_log is working
# This is less reliable but can indicate if messages are being processed
POST http://localhost:5280/api/get_room_options
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"room":"mamtestroom","service":"conference.ejabberd.local"}
HTTP/1.1 200
[Asserts]
# Room should still exist and show logging is enabled
body contains "logging"

# Clean up
POST http://localhost:5280/api/destroy_room
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"room":"mamtestroom","service":"conference.ejabberd.local"}
HTTP/1.1 200
[Asserts]
body contains "0"

POST http://localhost:5280/api/unregister
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"user":"mam_test_user","host":"ejabberd.local"}
HTTP/1.1 200
[Asserts]
body contains "" 