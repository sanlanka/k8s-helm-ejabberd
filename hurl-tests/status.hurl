# status.hurl

POST http://localhost:5280/api/status
Authorization: Basic YXBpQGVqYWJiZXJkLmxvY2FsOmFwaS1zZXJ2aWNlLXBhc3N3b3Jk
Content-Type: application/json

{}

HTTP/1.1 200

[Asserts]
body contains "The node ejabberd@localhost is started"
