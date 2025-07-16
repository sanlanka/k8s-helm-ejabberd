# room_file_upload.hurl - Test file upload simulation

# Clean up: Unregister user and destroy room (idempotent)
POST http://localhost:5280/api/unregister
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"user":"file_user","host":"ejabberd.local"}
HTTP/1.1 *

POST http://localhost:5280/api/destroy_room
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"room":"filetestroom","service":"conference.ejabberd.local"}
HTTP/1.1 *

# Register user
POST http://localhost:5280/api/register
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"user":"file_user","host":"ejabberd.local","password":"password"}
HTTP/1.1 200
[Asserts]
body contains "successfully registered"

# Create room
POST http://localhost:5280/api/create_room
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"room":"filetestroom","service":"conference.ejabberd.local","host":"ejabberd.local"}
HTTP/1.1 200
[Asserts]
body contains "0"

# Simulate file upload by sending a message with image URL
POST http://localhost:5280/api/send_message
Authorization: Basic ZmlsZV91c2VyQGVqYWJiZXJkLmxvY2FsOnBhc3N3b3Jk
Content-Type: application/json
{"type":"groupchat","from":"file_user@ejabberd.local","to":"filetestroom@conference.ejabberd.local","subject":"","body":"📷 Image shared: https://example.com/uploads/test-image.jpg"}
HTTP/1.1 200
[Asserts]
body contains "0"

# Simulate audio file upload by sending a message with audio URL
POST http://localhost:5280/api/send_message
Authorization: Basic ZmlsZV91c2VyQGVqYWJiZXJkLmxvY2FsOnBhc3N3b3Jk
Content-Type: application/json
{"type":"groupchat","from":"file_user@ejabberd.local","to":"filetestroom@conference.ejabberd.local","subject":"","body":"🎵 Audio shared: https://example.com/uploads/test-audio.mp3"}
HTTP/1.1 200
[Asserts]
body contains "0"

# Simulate document upload by sending a message with document URL
POST http://localhost:5280/api/send_message
Authorization: Basic ZmlsZV91c2VyQGVqYWJiZXJkLmxvY2FsOnBhc3N3b3Jk
Content-Type: application/json
{"type":"groupchat","from":"file_user@ejabberd.local","to":"filetestroom@conference.ejabberd.local","subject":"","body":"📄 Document shared: https://example.com/uploads/test-document.pdf"}
HTTP/1.1 200
[Asserts]
body contains "0"

# Test file sharing with metadata (simulated rich media message)
POST http://localhost:5280/api/send_message
Authorization: Basic ZmlsZV91c2VyQGVqYWJiZXJkLmxvY2FsOnBhc3N3b3Jk
Content-Type: application/json
{"type":"groupchat","from":"file_user@ejabberd.local","to":"filetestroom@conference.ejabberd.local","subject":"","body":"📎 File: vacation-photos.zip (2.3 MB)\n🔗 https://example.com/uploads/vacation-photos.zip"}
HTTP/1.1 200
[Asserts]
body contains "0"

# Clean up: Destroy room and unregister user
POST http://localhost:5280/api/destroy_room
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"room":"filetestroom","service":"conference.ejabberd.local"}
HTTP/1.1 200
[Asserts]
body contains "0"

POST http://localhost:5280/api/unregister
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"user":"file_user","host":"ejabberd.local"}
HTTP/1.1 200 