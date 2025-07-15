# ejabberd Kubernetes Deployment - Complete User API Reference

A comprehensive guide for all user actions and API endpoints available in the ejabberd XMPP server deployment.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Authentication](#authentication)
3. [User Management](#user-management)
4. [Room Management (MUC)](#room-management-muc)
5. [Messaging](#messaging)
6. [Presence & Status](#presence--status)
7. [Roster Management](#roster-management)
8. [User Profile (vCard)](#user-profile-vcard)
9. [System Information](#system-information)
10. [Advanced Features](#advanced-features)
11. [Error Handling](#error-handling)
12. [Testing & Examples](#testing--examples)

---

## Quick Start

### Prerequisites
- Kubernetes cluster with ejabberd deployed
- Port forwarding setup: `kubectl port-forward svc/ejabberd 5280:5280`
- Admin credentials: `admin@ejabberd.local` / `password`

### Base URL
```
http://localhost:5280/api/
```

### Authentication
All API calls use HTTP Basic Authentication with username:password encoded in base64.

---

## Authentication

### Available Authentication Methods

1. **Admin Account** (Full Access)
    - Username: `admin@ejabberd.local`
    - Password: `password`
    - Access: All API endpoints

2. **Service Account** (Admin Access)
    - Username: `api@ejabberd.local`
    - Password: `api-password`
    - Access: All API endpoints

3. **Regular Users** (Limited Access)
    - Username: `{username}@ejabberd.local`
    - Password: User-defined during registration
    - Access: Limited to user-specific endpoints

### Authentication Header Format
```bash
# Base64 encode username:password
echo -n "admin@ejabberd.local:password" | base64
# Result: YWRtaW5AZWphYmJlcmQubG9jYWw6cGFzc3dvcmQ=

# Use in API calls
curl -H "Authorization: Basic YWRtaW5AZWphYmJlcmQubG9jYWw6cGFzc3dvcmQ=" \
     -H "Content-Type: application/json" \
     -X POST http://localhost:5280/api/status \
     -d '{}'
```

---

## User Management

### 1. Register New User

**Endpoint:** `POST /api/register`  
**Access:** Admin only  
**Description:** Create a new user account

**Request:**
```bash
curl -X POST http://localhost:5280/api/register \
  -H "Authorization: Basic YWRtaW5AZWphYmJlcmQubG9jYWw6cGFzc3dvcmQ=" \
  -H "Content-Type: application/json" \
  -d '{
    "user": "alice",
    "host": "ejabberd.local",
    "password": "alice123"
  }'
```

**Response:**
```json
{
  "result": "ok"
}
```

### 2. Check User Registration

**Endpoint:** `POST /api/check_account`  
**Access:** Admin only  
**Description:** Verify if a user account exists

**Request:**
```bash
curl -X POST http://localhost:5280/api/check_account \
  -H "Authorization: Basic YWRtaW5AZWphYmJlcmQubG9jYWw6cGFzc3dvcmQ=" \
  -H "Content-Type: application/json" \
  -d '{
    "user": "alice",
    "host": "ejabberd.local"
  }'
```

**Response:**
```json
{
  "result": 0  // 0 = exists, 1 = doesn't exist
}
```

### 3. Change User Password

**Endpoint:** `POST /api/change_password`  
**Access:** Admin only  
**Description:** Change password for an existing user

**Request:**
```bash
curl -X POST http://localhost:5280/api/change_password \
  -H "Authorization: Basic YWRtaW5AZWphYmJlcmQubG9jYWw6cGFzc3dvcmQ=" \
  -H "Content-Type: application/json" \
  -d '{
    "user": "alice",
    "host": "ejabberd.local",
    "newpass": "newpassword123"
  }'
```

### 4. Delete User

**Endpoint:** `POST /api/unregister`  
**Access:** Admin only  
**Description:** Remove a user account

**Request:**
```bash
curl -X POST http://localhost:5280/api/unregister \
  -H "Authorization: Basic YWRtaW5AZWphYmJlcmQubG9jYWw6cGFzc3dvcmQ=" \
  -H "Content-Type: application/json" \
  -d '{
    "user": "alice",
    "host": "ejabberd.local"
  }'
```

---

## Room Management (MUC)

Multi-User Chat (MUC) service is available at `conference.ejabberd.local`

### 1. List Online Rooms

**Endpoint:** `POST /api/muc_online_rooms`  
**Access:** Admin, API service, Users (with JWT)  
**Description:** Get list of currently active chat rooms

**Request:**
```bash
curl -X POST http://localhost:5280/api/muc_online_rooms \
  -H "Authorization: Basic YWRtaW5AZWphYmJlcmQubG9jYWw6cGFzc3dvcmQ=" \
  -H "Content-Type: application/json" \
  -d '{
    "service": "conference.ejabberd.local"
  }'
```

**Response:**
```json
{
  "result": ["room1@conference.ejabberd.local", "room2@conference.ejabberd.local"]
}
```

### 2. Create Room

**Endpoint:** `POST /api/create_room`  
**Access:** Admin, API service, Local users  
**Description:** Create a new chat room

**Request:**
```bash
curl -X POST http://localhost:5280/api/create_room \
  -H "Authorization: Basic YWRtaW5AZWphYmJlcmQubG9jYWw6cGFzc3dvcmQ=" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my-room",
    "service": "conference.ejabberd.local",
    "host": "ejabberd.local"
  }'
```

**Response:**
```json
{
  "result": "ok"
}
```

### 3. Get Room Occupants

**Endpoint:** `POST /api/get_room_occupants`  
**Access:** Admin, API service, Users (with JWT)  
**Description:** List users currently in a room

**Request:**
```bash
curl -X POST http://localhost:5280/api/get_room_occupants \
  -H "Authorization: Basic YWRtaW5AZWphYmJlcmQubG9jYWw6cGFzc3dvcmQ=" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my-room",
    "service": "conference.ejabberd.local"
  }'
```

**Response:**
```json
{
  "result": [
    {
      "jid": "alice@ejabberd.local/resource",
      "nick": "alice",
      "role": "participant"
    }
  ]
}
```

### 4. Get Room Options

**Endpoint:** `POST /api/get_room_options`  
**Access:** Admin, API service, Users (with JWT)  
**Description:** Get room configuration options

**Request:**
```bash
curl -X POST http://localhost:5280/api/get_room_options \
  -H "Authorization: Basic YWRtaW5AZWphYmJlcmQubG9jYWw6cGFzc3dvcmQ=" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my-room",
    "service": "conference.ejabberd.local"
  }'
```

### 5. Destroy Room

**Endpoint:** `POST /api/destroy_room`  
**Access:** Admin, API service  
**Description:** Permanently delete a chat room

**Request:**
```bash
curl -X POST http://localhost:5280/api/destroy_room \
  -H "Authorization: Basic YWRtaW5AZWphYmJlcmQubG9jYWw6cGFzc3dvcmQ=" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my-room",
    "service": "conference.ejabberd.local"
  }'
```

---

## Messaging

### 1. Send Message to User (Direct Message)

**Endpoint:** `POST /api/send_message`  
**Access:** Admin, API service, Local users  
**Description:** Send a direct message to another user

**Request:**
```bash
curl -X POST http://localhost:5280/api/send_message \
  -H "Authorization: Basic YWxpY2VAZWphYmJlcmQubG9jYWw6YWxpY2UxMjM=" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "chat",
    "from": "alice@ejabberd.local",
    "to": "bob@ejabberd.local",
    "subject": "",
    "body": "Hello Bob! How are you?"
  }'
```

### 2. Send Message to Room (Group Chat)

**Endpoint:** `POST /api/send_message`  
**Access:** Admin, API service, Local users  
**Description:** Send a message to a chat room

**Request:**
```bash
curl -X POST http://localhost:5280/api/send_message \
  -H "Authorization: Basic YWxpY2VAZWphYmJlcmQubG9jYWw6YWxpY2UxMjM=" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "groupchat",
    "from": "alice@ejabberd.local",
    "to": "my-room@conference.ejabberd.local",
    "subject": "",
    "body": "Hello everyone! 👋"
  }'
```

### 3. Send Chat State (Typing Indicators)

**Endpoint:** `POST /api/send_chat_state`  
**Access:** Local users  
**Description:** Send typing indicators (composing, paused, active, inactive, gone)

**Request:**
```bash
curl -X POST http://localhost:5280/api/send_chat_state \
  -H "Authorization: Basic YWxpY2VAZWphYmJlcmQubG9jYWw6YWxpY2UxMjM=" \
  -H "Content-Type: application/json" \
  -d '{
    "from": "alice@ejabberd.local",
    "to": "bob@ejabberd.local",
    "state": "composing"
  }'
```

**Chat States:**
- `active` - User is actively participating
- `inactive` - User is not actively participating
- `gone` - User has left the conversation
- `composing` - User is typing
- `paused` - User was typing but paused

---

## Presence & Status

### 1. Get User Presence

**Endpoint:** `POST /api/get_presence`  
**Access:** Admin, API service, Local users  
**Description:** Get presence information for a user

**Request:**
```bash
curl -X POST http://localhost:5280/api/get_presence \
  -H "Authorization: Basic YWxpY2VAZWphYmJlcmQubG9jYWw6YWxpY2UxMjM=" \
  -H "Content-Type: application/json" \
  -d '{
    "user": "bob",
    "server": "ejabberd.local"
  }'
```

### 2. Set User Presence

**Endpoint:** `POST /api/set_presence`  
**Access:** Admin, API service, Local users  
**Description:** Set presence status for a user

**Request:**
```bash
curl -X POST http://localhost:5280/api/set_presence \
  -H "Authorization: Basic YWxpY2VAZWphYmJlcmQubG9jYWw6YWxpY2UxMjM=" \
  -H "Content-Type: application/json" \
  -d '{
    "user": "alice",
    "host": "ejabberd.local",
    "resource": "mobile",
    "type": "available",
    "show": "away",
    "status": "Out for lunch",
    "priority": "1"
  }'
```

**Presence Types:**
- `available` - User is online
- `unavailable` - User is offline

**Show Values:**
- `away` - Away
- `chat` - Available for chat
- `dnd` - Do not disturb
- `xa` - Extended away

### 3. Check Server Status

**Endpoint:** `POST /api/status`  
**Access:** Admin, API service, Users (with JWT)  
**Description:** Get server status and uptime

**Request:**
```bash
curl -X POST http://localhost:5280/api/status \
  -H "Authorization: Basic YWRtaW5AZWphYmJlcmQubG9jYWw6cGFzc3dvcmQ=" \
  -H "Content-Type: application/json" \
  -d '{}'
```

---

## Roster Management

### 1. Get User Roster

**Endpoint:** `POST /api/get_roster`  
**Access:** Admin, API service, Local users  
**Description:** Get user's contact list

**Request:**
```bash
curl -X POST http://localhost:5280/api/get_roster \
  -H "Authorization: Basic YWxpY2VAZWphYmJlcmQubG9jYWw6YWxpY2UxMjM=" \
  -H "Content-Type: application/json" \
  -d '{
    "user": "alice",
    "server": "ejabberd.local"
  }'
```

### 2. Add Contact to Roster

**Endpoint:** `POST /api/add_rosteritem`  
**Access:** Local users  
**Description:** Add a contact to user's roster

**Request:**
```bash
curl -X POST http://localhost:5280/api/add_rosteritem \
  -H "Authorization: Basic YWxpY2VAZWphYmJlcmQubG9jYWw6YWxpY2UxMjM=" \
  -H "Content-Type: application/json" \
  -d '{
    "localuser": "alice",
    "localserver": "ejabberd.local",
    "user": "bob",
    "server": "ejabberd.local",
    "nick": "Bob Smith",
    "group": "Friends",
    "subs": "both"
  }'
```

**Subscription Types:**
- `both` - Mutual subscription
- `from` - Contact can see your presence
- `to` - You can see contact's presence
- `none` - No subscription

### 3. Remove Contact from Roster

**Endpoint:** `POST /api/delete_rosteritem`  
**Access:** Local users  
**Description:** Remove a contact from user's roster

**Request:**
```bash
curl -X POST http://localhost:5280/api/delete_rosteritem \
  -H "Authorization: Basic YWxpY2VAZWphYmJlcmQubG9jYWw6YWxpY2UxMjM=" \
  -H "Content-Type: application/json" \
  -d '{
    "localuser": "alice",
    "localserver": "ejabberd.local",
    "user": "bob",
    "server": "ejabberd.local"
  }'
```

### 4. Subscribe to Contact

**Endpoint:** `POST /api/subscribe_roster`  
**Access:** Local users  
**Description:** Send subscription request to a contact

**Request:**
```bash
curl -X POST http://localhost:5280/api/subscribe_roster \
  -H "Authorization: Basic YWxpY2VAZWphYmJlcmQubG9jYWw6YWxpY2UxMjM=" \
  -H "Content-Type: application/json" \
  -d '{
    "localuser": "alice",
    "localserver": "ejabberd.local",
    "user": "bob",
    "server": "ejabberd.local"
  }'
```

---

## User Profile (vCard)

### 1. Get User vCard

**Endpoint:** `POST /api/get_vcard`  
**Access:** Admin, API service, Local users  
**Description:** Get user's profile information

**Request:**
```bash
curl -X POST http://localhost:5280/api/get_vcard \
  -H "Authorization: Basic YWxpY2VAZWphYmJlcmQubG9jYWw6YWxpY2UxMjM=" \
  -H "Content-Type: application/json" \
  -d '{
    "user": "alice",
    "host": "ejabberd.local"
  }'
```

### 2. Set User vCard

**Endpoint:** `POST /api/set_vcard`  
**Access:** Admin, API service, Local users  
**Description:** Update user's profile information

**Request:**
```bash
curl -X POST http://localhost:5280/api/set_vcard \
  -H "Authorization: Basic YWxpY2VAZWphYmJlcmQubG9jYWw6YWxpY2UxMjM=" \
  -H "Content-Type: application/json" \
  -d '{
    "user": "alice",
    "host": "ejabberd.local",
    "name": "FN",
    "content": "Alice Smith"
  }'
```

**Common vCard Fields:**
- `FN` - Full name
- `GIVEN` - First name
- `FAMILY` - Last name
- `NICKNAME` - Nickname
- `EMAIL` - Email address
- `TEL` - Phone number
- `ORG` - Organization
- `TITLE` - Job title
- `DESC` - Description/Bio

---

## System Information

### 1. Connected Users

**Endpoint:** `POST /api/connected_users`  
**Access:** Admin, API service, Users (with JWT)  
**Description:** Get list of currently connected users

**Request:**
```bash
curl -X POST http://localhost:5280/api/connected_users \
  -H "Authorization: Basic YWRtaW5AZWphYmJlcmQubG9jYWw6cGFzc3dvcmQ=" \
  -H "Content-Type: application/json" \
  -d '{}'
```

### 2. Connected Users Count

**Endpoint:** `POST /api/connected_users_number`  
**Access:** Admin, API service, Users (with JWT)  
**Description:** Get count of currently connected users

**Request:**
```bash
curl -X POST http://localhost:5280/api/connected_users_number \
  -H "Authorization: Basic YWRtaW5AZWphYmJlcmQubG9jYWw6cGFzc3dvcmQ=" \
  -H "Content-Type: application/json" \
  -d '{}'
```

### 3. Connected Users Info

**Endpoint:** `POST /api/connected_users_info`  
**Access:** Admin, API service, Users (with JWT)  
**Description:** Get detailed information about connected users

**Request:**
```bash
curl -X POST http://localhost:5280/api/connected_users_info \
  -H "Authorization: Basic YWRtaW5AZWphYmJlcmQubG9jYWw6cGFzc3dvcmQ=" \
  -H "Content-Type: application/json" \
  -d '{}'
```

### 4. User Session Info

**Endpoint:** `POST /api/user_sessions_info`  
**Access:** Admin, API service, Users (with JWT)  
**Description:** Get information about a specific user's sessions

**Request:**
```bash
curl -X POST http://localhost:5280/api/user_sessions_info \
  -H "Authorization: Basic YWRtaW5AZWphYmJlcmQubG9jYWw6cGFzc3dvcmQ=" \
  -H "Content-Type: application/json" \
  -d '{
    "user": "alice",
    "host": "ejabberd.local"
  }'
```

### 5. Get Offline Message Count

**Endpoint:** `POST /api/get_offline_count`  
**Access:** Local users  
**Description:** Get count of offline messages for a user

**Request:**
```bash
curl -X POST http://localhost:5280/api/get_offline_count \
  -H "Authorization: Basic YWxpY2VAZWphYmJlcmQubG9jYWw6YWxpY2UxMjM=" \
  -H "Content-Type: application/json" \
  -d '{
    "user": "alice",
    "server": "ejabberd.local"
  }'
```

---

## Advanced Features

### 1. Get User Rooms

**Endpoint:** `POST /api/get_user_rooms`  
**Access:** Local users  
**Description:** Get list of rooms a user has joined

**Request:**
```bash
curl -X POST http://localhost:5280/api/get_user_rooms \
  -H "Authorization: Basic YWxpY2VAZWphYmJlcmQubG9jYWw6YWxpY2UxMjM=" \
  -H "Content-Type: application/json" \
  -d '{
    "user": "alice",
    "host": "ejabberd.local"
  }'
```

### 2. Join Room

**Endpoint:** `POST /api/join_room`  
**Access:** Local users  
**Description:** Join a user to a chat room

**Request:**
```bash
curl -X POST http://localhost:5280/api/join_room \
  -H "Authorization: Basic YWxpY2VAZWphYmJlcmQubG9jYWw6YWxpY2UxMjM=" \
  -H "Content-Type: application/json" \
  -d '{
    "user": "alice",
    "host": "ejabberd.local",
    "room": "my-room",
    "service": "conference.ejabberd.local",
    "nick": "Alice"
  }'
```

### 3. Leave Room

**Endpoint:** `POST /api/leave_room`  
**Access:** Local users  
**Description:** Remove a user from a chat room

**Request:**
```bash
curl -X POST http://localhost:5280/api/leave_room \
  -H "Authorization: Basic YWxpY2VAZWphYmJlcmQubG9jYWw6YWxpY2UxMjM=" \
  -H "Content-Type: application/json" \
  -d '{
    "user": "alice",
    "host": "ejabberd.local",
    "room": "my-room",
    "service": "conference.ejabberd.local"
  }'
```

### 4. Send Direct Invitation

**Endpoint:** `POST /api/send_direct_invitation`  
**Access:** Local users  
**Description:** Send a direct invitation to join a room

**Request:**
```bash
curl -X POST http://localhost:5280/api/send_direct_invitation \
  -H "Authorization: Basic YWxpY2VAZWphYmJlcmQubG9jYWw6YWxpY2UxMjM=" \
  -H "Content-Type: application/json" \
  -d '{
    "room": "my-room",
    "service": "conference.ejabberd.local",
    "password": "",
    "reason": "Join our team discussion",
    "users": ["bob@ejabberd.local", "charlie@ejabberd.local"]
  }'
```

---

## Error Handling

### Common HTTP Status Codes

- `200` - Success
- `400` - Bad Request (invalid parameters)
- `401` - Unauthorized (authentication required)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found (endpoint doesn't exist)
- `500` - Internal Server Error

### Error Response Format

```json
{
  "error": "invalid_credentials",
  "message": "Authentication failed"
}
```

### Common Error Types

1. **Authentication Errors**
    - Invalid credentials
    - Missing authorization header
    - Expired tokens (for JWT)

2. **Permission Errors**
    - Insufficient privileges for endpoint
    - User not authorized for specific action

3. **Validation Errors**
    - Missing required parameters
    - Invalid parameter format
    - Invalid JID format

4. **Resource Errors**
    - User doesn't exist
    - Room doesn't exist
    - Server unreachable

---

## Testing & Examples

### Running the Test Suite

The project includes a comprehensive test suite in `ejabberd/tests/test_jwt_ejabberd.py`.

```bash
# Start port forwarding
kubectl port-forward svc/ejabberd 5280:5280 &

# Run tests
cd ejabberd/tests
python test_jwt_ejabberd.py
```

### Example: Complete User Workflow

```bash
# 1. Register a new user (as admin)
curl -X POST http://localhost:5280/api/register \
  -H "Authorization: Basic YWRtaW5AZWphYmJlcmQubG9jYWw6cGFzc3dvcmQ=" \
  -H "Content-Type: application/json" \
  -d '{"user": "alice", "host": "ejabberd.local", "password": "alice123"}'

# 2. Create a room (as admin)
curl -X POST http://localhost:5280/api/create_room \
  -H "Authorization: Basic YWRtaW5AZWphYmJlcmQubG9jYWw6cGFzc3dvcmQ=" \
  -H "Content-Type: application/json" \
  -d '{"name": "team-chat", "service": "conference.ejabberd.local", "host": "ejabberd.local"}'

# 3. User sends message to room
curl -X POST http://localhost:5280/api/send_message \
  -H "Authorization: Basic YWxpY2VAZWphYmJlcmQubG9jYWw6YWxpY2UxMjM=" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "groupchat",
    "from": "alice@ejabberd.local",
    "to": "team-chat@conference.ejabberd.local",
    "subject": "",
    "body": "Hello team! 👋"
  }'

# 4. Check who's in the room
curl -X POST http://localhost:5280/api/get_room_occupants \
  -H "Authorization: Basic YWxpY2VAZWphYmJlcmQubG9jYWw6YWxpY2UxMjM=" \
  -H "Content-Type: application/json" \
  -d '{"name": "team-chat", "service": "conference.ejabberd.local"}'
```

### Example: User Management Script

```python
import requests
import base64
import json

# Configuration
base_url = "http://localhost:5280/api"
admin_auth = base64.b64encode(b"admin@ejabberd.local:password").decode()

def api_call(endpoint, data, auth=admin_auth):
    headers = {
        "Authorization": f"Basic {auth}",
        "Content-Type": "application/json"
    }
    response = requests.post(f"{base_url}/{endpoint}", 
                           headers=headers, 
                           json=data)
    return response

# Register multiple users
users = ["alice", "bob", "charlie"]
for user in users:
    result = api_call("register", {
        "user": user,
        "host": "ejabberd.local", 
        "password": f"{user}123"
    })
    print(f"Created user {user}: {result.status_code}")

# Create team room
room_result = api_call("create_room", {
    "name": "team-room",
    "service": "conference.ejabberd.local",
    "host": "ejabberd.local"
})
print(f"Created room: {room_result.status_code}")
```

---

## Key Features Summary

### ✅ Working Features

1. **User Management**
    - User registration (admin only)
    - Password management
    - Account verification

2. **Room Management**
    - Create/destroy rooms
    - List active rooms
    - Get room information and occupants

3. **Messaging**
    - Direct messages between users
    - Group chat in rooms
    - Message delivery confirmation

4. **Presence & Status**
    - Set/get user presence
    - Online user tracking
    - Session management

5. **Roster Management**
    - Add/remove contacts
    - Subscription management
    - Contact groups

6. **Profile Management**
    - vCard support
    - User profile information

### 🔐 Security Notes

- All API endpoints require authentication
- Users can only perform actions on their own account (except admins)
- Room access follows standard XMPP MUC permissions
- Admin accounts have full system access

### 📱 Client Integration

This API can be integrated with:
- Web applications (JavaScript/REST)
- Mobile apps (iOS/Android)
- Desktop applications
- Bots and automation scripts
- Third-party XMPP clients

---

For questions or issues, check the test suite in `ejabberd/tests/test_jwt_ejabberd.py` for working examples of all API endpoints. 