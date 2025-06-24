# Core Messaging Tests
# Test essential messaging functionality between users

# Send a simple chat message
POST {{base_url}}/api/send_message
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "type": "chat",
  "from": "testuser@{{domain}}",
  "to": "friend@{{domain}}",
  "subject": "Hello",
  "body": "Hello friend! How are you doing today?"
}
HTTP 200

# Send message with rich content (HTML)
POST {{base_url}}/api/send_message
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "type": "chat",
  "from": "testuser@{{domain}}",
  "to": "friend@{{domain}}",
  "subject": "Rich Message",
  "body": "Check out this <b>bold text</b> and <a href='https://example.com'>link</a>!"
}
HTTP 200

# Send message with custom stanza (advanced messaging)
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "testuser@{{domain}}",
  "to": "friend@{{domain}}",
  "stanza": "<message type='chat' id='msg1'><body>Custom stanza message</body><thread>conversation-123</thread><x xmlns='jabber:x:delay' stamp='2024-01-01T12:00:00Z'/></message>"
}
HTTP 200

# Send message with receipt request
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "testuser@{{domain}}",
  "to": "friend@{{domain}}",
  "stanza": "<message type='chat' id='msg2'><body>Please confirm you received this</body><request xmlns='urn:xmpp:receipts'/></message>"
}
HTTP 200

# Send delivery receipt
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "friend@{{domain}}",
  "to": "testuser@{{domain}}",
  "stanza": "<message type='chat'><received xmlns='urn:xmpp:receipts' id='msg2'/></message>"
}
HTTP 200

# Send message with attention/buzz
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "testuser@{{domain}}",
  "to": "friend@{{domain}}",
  "stanza": "<message type='chat'><body>Urgent message!</body><attention xmlns='urn:xmpp:attention:0'/></message>"
}
HTTP 200

# Send message to multiple resources
POST {{base_url}}/api/send_message
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "type": "chat",
  "from": "testuser@{{domain}}",
  "to": "friend@{{domain}}",
  "subject": "Multi-resource",
  "body": "This message should reach all your devices"
}
HTTP 200

# Test message correction (XEP-0308)
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "testuser@{{domain}}",
  "to": "friend@{{domain}}",
  "stanza": "<message type='chat' id='correction1'><body>This is the corrected message text</body><replace id='msg1' xmlns='urn:xmpp:message-correct:0'/></message>"
}
HTTP 200

# Test carbon copy (message forwarding)
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "testuser@{{domain}}",
  "to": "testuser@{{domain}}",
  "stanza": "<iq type='set' id='carbons1'><enable xmlns='urn:xmpp:carbons:2'/></iq>"
}
HTTP 200

# Send message with emoji and unicode
POST {{base_url}}/api/send_message
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "type": "chat",
  "from": "testuser@{{domain}}",
  "to": "friend@{{domain}}",
  "subject": "Fun Message",
  "body": "Hello! 😊 Check out these emojis: 🚀🎉🌟 and international text: こんにちは, Привет, مرحبا"
}
HTTP 200 