# Push Notifications and Advanced Features Tests
# Test push notifications, file sharing, and modern chat features

# Test push notification setup (XEP-0357)
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "testuser@{{domain}}",
  "to": "testuser@{{domain}}",
  "stanza": "<iq type='set' id='push1'><enable xmlns='urn:xmpp:push:0' jid='push.example.com' node='user123'><x xmlns='jabber:x:data' type='form'><field var='FORM_TYPE' type='hidden'><value>http://jabber.org/protocol/pubsub#publish-options</value></field><field var='secret'><value>MySecret</value></field></x></enable></iq>"
}
HTTP 200

# Test file upload capability (HTTP File Upload - XEP-0363)
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "testuser@{{domain}}",
  "to": "upload.{{domain}}",
  "stanza": "<iq type='get' id='upload1'><request xmlns='urn:xmpp:http:upload:0' filename='test-image.jpg' size='12345' content-type='image/jpeg'/></iq>"
}
HTTP 200

# Test service discovery for upload service
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "testuser@{{domain}}",
  "to": "upload.{{domain}}",
  "stanza": "<iq type='get' id='disco_upload'><query xmlns='http://jabber.org/protocol/disco#info'/></iq>"
}
HTTP 200

# Send message with file attachment reference
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "testuser@{{domain}}",
  "to": "friend@{{domain}}",
  "stanza": "<message type='chat'><body>Check out this image!</body><reference xmlns='urn:xmpp:reference:0' type='data' uri='https://upload.example.com/files/test-image.jpg'><media-sharing xmlns='urn:xmpp:sims:1'><file xmlns='urn:xmpp:jingle:apps:file-transfer:5'><media-type>image/jpeg</media-type><name>test-image.jpg</name><size>12345</size></file></media-sharing></reference></message>"
}
HTTP 200

# Test Stream Management (XEP-0198) for reliable message delivery
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "testuser@{{domain}}",
  "to": "testuser@{{domain}}",
  "stanza": "<enable xmlns='urn:xmpp:sm:3' resume='true'/>"
}
HTTP 200

# Test Message Acknowledgment
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "testuser@{{domain}}",
  "to": "testuser@{{domain}}",
  "stanza": "<a xmlns='urn:xmpp:sm:3' h='5'/>"
}
HTTP 200

# Test PubSub for user mood/activity
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "testuser@{{domain}}",
  "to": "pubsub.{{domain}}",
  "stanza": "<iq type='set' id='mood1'><pubsub xmlns='http://jabber.org/protocol/pubsub'><publish node='http://jabber.org/protocol/mood'><item id='current'><mood xmlns='http://jabber.org/protocol/mood'><happy/><text>Having a great day!</text></mood></item></publish></pubsub></iq>"
}
HTTP 200

# Test user activity publication
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "testuser@{{domain}}",
  "to": "pubsub.{{domain}}",
  "stanza": "<iq type='set' id='activity1'><pubsub xmlns='http://jabber.org/protocol/pubsub'><publish node='http://jabber.org/protocol/activity'><item id='current'><activity xmlns='http://jabber.org/protocol/activity'><working/><text>Coding some awesome features</text></activity></item></publish></pubsub></iq>"
}
HTTP 200

# Test geolocation sharing
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "testuser@{{domain}}",
  "to": "pubsub.{{domain}}",
  "stanza": "<iq type='set' id='geo1'><pubsub xmlns='http://jabber.org/protocol/pubsub'><publish node='http://jabber.org/protocol/geoloc'><item id='current'><geoloc xmlns='http://jabber.org/protocol/geoloc'><lat>37.7749</lat><lon>-122.4194</lon><locality>San Francisco</locality><country>USA</country></geoloc></item></publish></pubsub></iq>"
}
HTTP 200

# Test message reactions (XEP-0444)
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "testuser@{{domain}}",
  "to": "friend@{{domain}}",
  "stanza": "<message type='chat'><reactions xmlns='urn:xmpp:reactions:0' id='msg-original'><reaction>👍</reaction><reaction>❤️</reaction></reactions></message>"
}
HTTP 200

# Test message retraction (XEP-0424)
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "testuser@{{domain}}",
  "to": "friend@{{domain}}",
  "stanza": "<message type='chat'><apply-to xmlns='urn:xmpp:fasten:0' id='msg-to-retract'><retract xmlns='urn:xmpp:message-retract:0'/></apply-to><fallback xmlns='urn:xmpp:fallback:0' for='urn:xmpp:message-retract:0'>This person retracted a message</fallback></message>"
}
HTTP 200

# Test occupant-id for MUC privacy
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "testuser@{{domain}}/nick",
  "to": "testroom@conference.{{domain}}",
  "stanza": "<message type='groupchat'><body>Anonymous group message</body><occupant-id xmlns='urn:xmpp:occupant-id:0' id='unique-occupant-123'/></message>"
}
HTTP 200

# Test message moderation (XEP-0425)
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "moderator@{{domain}}",
  "to": "testroom@conference.{{domain}}",
  "stanza": "<message type='groupchat'><apply-to xmlns='urn:xmpp:fasten:0' id='msg-to-moderate'><moderate xmlns='urn:xmpp:message-moderate:0'><retract xmlns='urn:xmpp:message-retract:0'/><reason>Inappropriate content</reason></moderate></apply-to></message>"
}
HTTP 200

# Test call invite (Jingle/SIP integration)
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "testuser@{{domain}}",
  "to": "friend@{{domain}}",
  "stanza": "<message type='chat'><body>Incoming call...</body><call xmlns='urn:xmpp:call:0' id='call-123'><audio/></call></message>"
}
HTTP 200

# Test encryption readiness check (OMEMO support)
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "testuser@{{domain}}",
  "to": "testuser@{{domain}}",
  "stanza": "<iq type='get' id='omemo1'><pubsub xmlns='http://jabber.org/protocol/pubsub'><items node='eu.siacs.conversations.axolotl.devicelist'/></pubsub></iq>"
}
HTTP 200

# Test roster versioning for efficient sync
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "testuser@{{domain}}",
  "to": "testuser@{{domain}}",
  "stanza": "<iq type='get' id='roster_ver'><query xmlns='jabber:iq:roster' ver='current-version'/></iq>"
}
HTTP 200

# Delete old push sessions (cleanup)
POST {{base_url}}/api/delete_old_push_sessions
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "host": "{{domain}}",
  "days": "30"
}
HTTP 200 