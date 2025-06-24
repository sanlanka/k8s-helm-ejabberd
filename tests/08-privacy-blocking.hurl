# Privacy and Blocking Tests
# Test privacy controls, blocking users, and private data storage

# Set privacy list to block a specific user
POST {{base_url}}/api/privacy_set
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "user": "testuser",
  "host": "{{domain}}",
  "xmlquery": "<list name='blocked-users'><item type='jid' value='spam@{{domain}}' action='deny' order='1'><message/><presence-in/><presence-out/><iq/></item></list>"
}
HTTP 200

# Set privacy list to allow only roster contacts
POST {{base_url}}/api/privacy_set
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "user": "testuser",
  "host": "{{domain}}",
  "xmlquery": "<list name='roster-only'><item type='subscription' value='none' action='deny' order='1'><message/><presence-in/></item><item action='allow' order='2'/></list>"
}
HTTP 200

# Set privacy list to block all communication during DND
POST {{base_url}}/api/privacy_set
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "user": "testuser",
  "host": "{{domain}}",
  "xmlquery": "<list name='dnd-mode'><item action='deny' order='1'><message/></item><item type='subscription' value='both' action='allow' order='2'><message/></item></list>"
}
HTTP 200

# Activate a privacy list
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "testuser@{{domain}}",
  "to": "testuser@{{domain}}",
  "stanza": "<iq type='set' id='privacy1'><query xmlns='jabber:iq:privacy'><active name='blocked-users'/></query></iq>"
}
HTTP 200

# Get current privacy settings
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "testuser@{{domain}}",
  "to": "testuser@{{domain}}",
  "stanza": "<iq type='get' id='privacy2'><query xmlns='jabber:iq:privacy'/></iq>"
}
HTTP 200

# Test private XML storage (for app-specific data)
POST {{base_url}}/api/private_set
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "user": "testuser",
  "host": "{{domain}}",
  "element": "<settings xmlns='urn:example:app:settings'><theme>dark</theme><notifications>true</notifications><sound>enabled</sound></settings>"
}
HTTP 200

# Store user preferences in private storage
POST {{base_url}}/api/private_set
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "user": "testuser",
  "host": "{{domain}}",
  "element": "<preferences xmlns='urn:example:chat:prefs'><auto-away>600</auto-away><show-offline>false</show-offline><group-chat-notifications>true</group-chat-notifications></preferences>"
}
HTTP 200

# Store bookmarks in private storage
POST {{base_url}}/api/private_set
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "user": "testuser",
  "host": "{{domain}}",
  "element": "<storage xmlns='storage:bookmarks'><conference name='Dev Team' jid='dev@conference.{{domain}}'><nick>TestUser</nick></conference><conference name='General' jid='general@conference.{{domain}}'><nick>TestUser</nick><password>secret</password></conference></storage>"
}
HTTP 200

# Retrieve private storage data
GET {{base_url}}/api/private_get/testuser@{{domain}}/storage:bookmarks/storage
Authorization: Bearer {{access_token}}
HTTP 200

# Get user preferences from private storage
GET {{base_url}}/api/private_get/testuser@{{domain}}/urn:example:chat:prefs/preferences
Authorization: Bearer {{access_token}}
HTTP 200

# Get app settings from private storage
GET {{base_url}}/api/private_get/testuser@{{domain}}/urn:example:app:settings/settings
Authorization: Bearer {{access_token}}
HTTP 200

# Test blocking via roster subscription
POST {{base_url}}/api/add_rosteritem
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "localuser": "testuser",
  "localserver": "{{domain}}",
  "user": "blocked",
  "server": "{{domain}}",
  "nick": "Blocked User",
  "group": "blocked",
  "subs": "none"
}
HTTP 200

# Remove blocked user from roster
POST {{base_url}}/api/delete_rosteritem
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "localuser": "testuser",
  "localserver": "{{domain}}",
  "user": "blocked",
  "server": "{{domain}}"
}
HTTP 200

# Test service discovery for privacy features
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "testuser@{{domain}}",
  "to": "{{domain}}",
  "stanza": "<iq type='get' id='disco1'><query xmlns='http://jabber.org/protocol/disco#info'/></iq>"
}
HTTP 200

# Deactivate privacy list
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "testuser@{{domain}}",
  "to": "testuser@{{domain}}",
  "stanza": "<iq type='set' id='privacy3'><query xmlns='jabber:iq:privacy'><active/></query></iq>"
}
HTTP 200 