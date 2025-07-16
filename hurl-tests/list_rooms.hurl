# rooms_flow.hurl

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

# Create room2
POST http://localhost:5280/api/create_room
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json
{"room":"testroom2","service":"conference.ejabberd.local","host":"ejabberd.local"}
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
