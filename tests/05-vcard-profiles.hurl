# vCard and User Profile Tests
# Test user profiles, contact information, and avatar management

# Set comprehensive vCard information
POST {{base_url}}/api/set_vcard
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "user": "testuser",
  "host": "{{domain}}",
  "name": "FN",
  "content": "John Test User"
}
HTTP 200

# Set user's nickname
POST {{base_url}}/api/set_vcard
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "user": "testuser",
  "host": "{{domain}}",
  "name": "NICKNAME",
  "content": "Johnny"
}
HTTP 200

# Set user's email
POST {{base_url}}/api/set_vcard
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "user": "testuser",
  "host": "{{domain}}",
  "name": "EMAIL",
  "content": "john@example.com"
}
HTTP 200

# Set user's phone number
POST {{base_url}}/api/set_vcard
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "user": "testuser",
  "host": "{{domain}}",
  "name": "TEL",
  "content": "+1-555-123-4567"
}
HTTP 200

# Set user's organization
POST {{base_url}}/api/set_vcard
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "user": "testuser",
  "host": "{{domain}}",
  "name": "ORG",
  "content": "Test Company Inc."
}
HTTP 200

# Set user's job title
POST {{base_url}}/api/set_vcard
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "user": "testuser",
  "host": "{{domain}}",
  "name": "TITLE",
  "content": "Software Engineer"
}
HTTP 200

# Set user's website
POST {{base_url}}/api/set_vcard
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "user": "testuser",
  "host": "{{domain}}",
  "name": "URL",
  "content": "https://john.example.com"
}
HTTP 200

# Set user's birthday
POST {{base_url}}/api/set_vcard
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "user": "testuser",
  "host": "{{domain}}",
  "name": "BDAY",
  "content": "1990-01-15"
}
HTTP 200

# Get user's complete vCard
GET {{base_url}}/api/get_vcard/testuser@{{domain}}
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$.vcard" exists

# Set user's avatar/photo (base64 encoded)
POST {{base_url}}/api/set_vcard
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "user": "testuser",
  "host": "{{domain}}",
  "name": "PHOTO",
  "content": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="
}
HTTP 200

# Test vCard2 format (XML-based)
POST {{base_url}}/api/set_vcard2
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "user": "testuser",
  "host": "{{domain}}",
  "name": "DESC",
  "content": "Passionate software engineer who loves building chat applications"
}
HTTP 200

# Get vCard2 format
GET {{base_url}}/api/get_vcard2/testuser@{{domain}}
Authorization: Bearer {{access_token}}
HTTP 200

# Set multiple vCard fields at once
POST {{base_url}}/api/set_vcard2_multi
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "user": "testuser",
  "host": "{{domain}}",
  "contents": [
    {
      "name": "ADR",
      "content": ";;123 Main St;Anytown;CA;12345;USA"
    },
    {
      "name": "GEO",
      "content": "37.7749,-122.4194"
    }
  ]
}
HTTP 200

# Get multiple vCard fields
GET {{base_url}}/api/get_vcard2_multi/testuser@{{domain}}
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$" isCollection

# Set roster nickname (different from vCard nickname)
POST {{base_url}}/api/set_nickname
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "user": "testuser",
  "host": "{{domain}}",
  "nickname": "TestUserNick"
}
HTTP 200

# Test profile discovery via service discovery
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "admin@{{domain}}",
  "to": "testuser@{{domain}}",
  "stanza": "<iq type='get'><query xmlns='http://jabber.org/protocol/disco#info'/></iq>"
}
HTTP 200

# Test vCard-temp namespace (legacy vCard support)
POST {{base_url}}/api/send_stanza
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "from": "admin@{{domain}}",
  "to": "testuser@{{domain}}",
  "stanza": "<iq type='get'><vCard xmlns='vcard-temp'/></iq>"
}
HTTP 200 