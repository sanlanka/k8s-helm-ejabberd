# First, destroy the room to ensure a clean state.
# We expect this to fail if the room doesn't exist, so we use a wildcard status.
POST http://localhost:5280/api/destroy_room
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json

{"room":"testroom","service":"conference.ejabberd.local"}

HTTP/1.1 *

# Then, create the room
POST http://localhost:5280/api/create_room
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json

{"room":"testroom","service":"conference.ejabberd.local","host":"ejabberd.local"}

HTTP/1.1 200
[Asserts]
body contains "0"
