# Message Archive Management (MAM) Tests
# Test message history, archiving, and retrieval functionality

# Send some messages to create archive history
POST {{base_url}}/api/send_message
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "type": "chat",
  "from": "testuser@{{domain}}",
  "to": "friend@{{domain}}",
  "subject": "Test Archive Message 1",
  "body": "This is the first test message for archiving"
}
HTTP 200

POST {{base_url}}/api/send_message
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "type": "chat",
  "from": "friend@{{domain}}",
  "to": "testuser@{{domain}}",
  "subject": "Test Archive Message 2",
  "body": "This is the second test message for archiving"
}
HTTP 200

POST {{base_url}}/api/send_message
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "type": "chat",
  "from": "testuser@{{domain}}",
  "to": "friend@{{domain}}",
  "subject": "Test Archive Message 3",
  "body": "This is the third test message with special keyword: important"
}
HTTP 200

# Get MAM (Message Archive Management) count for user
GET {{base_url}}/api/get_mam_count/testuser@{{domain}}/testuser@{{domain}}/friend@{{domain}}
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$.value" isInteger

# Test MAM query to retrieve message history
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "testuser@{{domain}}",
  "to": "testuser@{{domain}}",
  "stanza": "<iq type='set' id='mam1'><query xmlns='urn:xmpp:mam:2'><x xmlns='jabber:x:data' type='submit'><field var='FORM_TYPE' type='hidden'><value>urn:xmpp:mam:2</value></field><field var='with'><value>friend@{{domain}}</value></field></x></query></iq>"
}
HTTP 200

# Test MAM query with date range
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "testuser@{{domain}}",
  "to": "testuser@{{domain}}",
  "stanza": "<iq type='set' id='mam2'><query xmlns='urn:xmpp:mam:2'><x xmlns='jabber:x:data' type='submit'><field var='FORM_TYPE' type='hidden'><value>urn:xmpp:mam:2</value></field><field var='start'><value>2024-01-01T00:00:00Z</value></field><field var='end'><value>2024-12-31T23:59:59Z</value></field></x></query></iq>"
}
HTTP 200

# Test MAM preferences query
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "testuser@{{domain}}",
  "to": "testuser@{{domain}}",
  "stanza": "<iq type='get' id='mamprefs1'><prefs xmlns='urn:xmpp:mam:2'/></iq>"
}
HTTP 200

# Set MAM preferences (always store messages)
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "testuser@{{domain}}",
  "to": "testuser@{{domain}}",
  "stanza": "<iq type='set' id='mamprefs2'><prefs xmlns='urn:xmpp:mam:2' default='always'><always><jid>friend@{{domain}}</jid></always></prefs></iq>"
}
HTTP 200

# Remove old MAM messages for testing cleanup
POST {{base_url}}/api/delete_old_mam_messages
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "host": "{{domain}}",
  "days": "0"
}
HTTP 200

# Get MAM deletion status
GET {{base_url}}/api/delete_old_mam_messages_status/{{domain}}
Authorization: Bearer {{access_token}}
HTTP 200

# Remove MAM messages for specific user
POST {{base_url}}/api/remove_mam_for_user
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "user": "tempuser",
  "host": "{{domain}}"
}
HTTP 200

# Remove MAM messages between specific users
POST {{base_url}}/api/remove_mam_for_user_with_peer
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "user": "testuser",
  "host": "{{domain}}",
  "with": "friend@{{domain}}"
}
HTTP 200 