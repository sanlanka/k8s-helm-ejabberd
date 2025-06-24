# Group Chat (MUC) Tests  
# Test comprehensive multi-user chat functionality

# Create a new MUC room
POST {{base_url}}/api/create_room
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "name": "testroom",
  "service": "conference.{{domain}}",
  "host": "{{domain}}"
}
HTTP 200

# Get room info
GET {{base_url}}/api/get_room_options/testroom@conference.{{domain}}
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$" isCollection

# Configure room options
POST {{base_url}}/api/change_room_option
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "name": "testroom",
  "service": "conference.{{domain}}",
  "option": "persistent",
  "value": "true"
}
HTTP 200

POST {{base_url}}/api/change_room_option
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "name": "testroom",
  "service": "conference.{{domain}}",
  "option": "public",
  "value": "true"
}
HTTP 200

# Set room subject
POST {{base_url}}/api/set_room_subject
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "name": "testroom",
  "service": "conference.{{domain}}",
  "subject": "Test Room for API Testing"
}
HTTP 200

# Join user to room (simulate)
POST {{base_url}}/api/send_direct_invitation
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "name": "testroom",
  "service": "conference.{{domain}}",
  "password": "",
  "reason": "Welcome to test room",
  "users": "testuser@{{domain}}"
}
HTTP 200

# Get room occupants
GET {{base_url}}/api/get_room_occupants/testroom@conference.{{domain}}
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$" isCollection

# Send message to room
POST {{base_url}}/api/send_message
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "type": "groupchat",
  "from": "admin@{{domain}}",
  "to": "testroom@conference.{{domain}}",
  "subject": "Test",
  "body": "Hello everyone in the test room!"
}
HTTP 200

# Get list of user's rooms
GET {{base_url}}/api/get_user_rooms/testuser@{{domain}}/conference.{{domain}}
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$" isCollection

# Get room history/archive if enabled
GET {{base_url}}/api/get_room_history/testroom@conference.{{domain}}
Authorization: Bearer {{access_token}}
HTTP 200

# Set room affiliation (make user member)
POST {{base_url}}/api/set_room_affiliation
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "name": "testroom",
  "service": "conference.{{domain}}",
  "jid": "testuser@{{domain}}",
  "affiliation": "member"
}
HTTP 200

# Get room affiliations
GET {{base_url}}/api/get_room_affiliations/testroom@conference.{{domain}}
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$" isCollection

# List all rooms
GET {{base_url}}/api/muc_online_rooms/conference.{{domain}}
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$" isCollection
jsonpath "$[*]" includes "testroom@conference.{{domain}}" 