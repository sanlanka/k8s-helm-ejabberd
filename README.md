# ejabberd Kubernetes Helm Chart

A production-ready Helm chart for deploying ejabberd XMPP server on Kubernetes with comprehensive HTTP API support, JWT authentication, and Skaffold integration for local development and CI/CD.

## 🚀 Quick Start

### Prerequisites

- Kubernetes cluster (local or cloud)
- [Helm 3.x](https://helm.sh/docs/intro/install/)
- [Skaffold](https://skaffold.dev/docs/install/) (optional, for development)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

### Local Development

```bash
# Start with live updates
skaffold dev

# Or deploy manually
helm install ejabberd ./ejabberd
```

### Production Deployment

```bash
# Deploy to production
skaffold run --profile=prod

# Or with Helm
helm upgrade --install ejabberd ./ejabberd -f values-prod.yaml
```

## 🔐 Authentication Methods

This ejabberd deployment supports multiple authentication methods for the HTTP API:

### 1. Basic Authentication (Username/Password)

**Default Admin User:**
- Username: `admin@ejabberd.local`
- Password: `admin123`

**Regular Users:**
- Username: `username@ejabberd.local`
- Password: `user_password`

```bash
# Admin API call
curl -u admin@ejabberd.local:admin123 -X POST http://localhost:5280/api/status \
  -H "Content-Type: application/json" \
  -d '{}'

# User API call
curl -u alice@ejabberd.local:alice123 -X POST http://localhost:5280/api/send_message \
  -H "Content-Type: application/json" \
  -d '{
    "type": "chat",
    "from": "alice@ejabberd.local",
    "to": "bob@ejabberd.local",
    "body": "Hello!"
  }'
```

### 2. JWT Token Authentication

**Generate JWT Token:**
```python
import jwt
from datetime import datetime, timedelta

# JWT secret (from Kubernetes secret)
SECRET_KEY = "dbTs3KDBI33vWdGGmJwv7UJJRwLQSamcQ"

def generate_jwt(user_jid, expiry_minutes=60):
    """Generate JWT for HTTP API access"""
    now = datetime.utcnow()
    payload = {
        'jid': user_jid,
        'iat': now,
        'exp': now + timedelta(minutes=expiry_minutes),
        'iss': 'ejabberd-api'
    }
    return jwt.encode(payload, SECRET_KEY, algorithm='HS256')

# Generate token for alice
token = generate_jwt("alice@ejabberd.local")
```

**Use JWT Token:**
```bash
# API call with JWT
curl -H "Authorization: Bearer $JWT_TOKEN" -X POST http://localhost:5280/api/send_message \
  -H "Content-Type: application/json" \
  -d '{
    "type": "chat",
    "from": "alice@ejabberd.local",
    "to": "bob@ejabberd.local",
    "body": "Hello via JWT!"
  }'
```

### 3. API Key Authentication

**Configure API Key:**
```yaml
# In ejabberd-config.yaml
modules:
  mod_http_api:
    api_key: "your-secure-api-key-here"
```

**Use API Key:**
```bash
curl -H "X-API-Key: your-secure-api-key-here" -X POST http://localhost:5280/api/status \
  -H "Content-Type: application/json" \
  -d '{}'
```

## 🔑 Service-to-Service Authentication

### Required Secrets and Credentials

When integrating other services with this ejabberd deployment, you'll need the following authentication secrets:

#### 1. JWT Secret Key

**Purpose:** Used for JWT token generation and validation
**Secret Name:** `ejabberd-jwt-key`
**Key:** `jwt-key`
**Default Value:** `{"kty":"oct","k":"ZGJUczNLREIzM3ZXZEdHbUp3djdVSkpSd0xRU2FtY1E="}`

**How to get it:**
```bash
# Get the JWT secret from Kubernetes
kubectl get secret ejabberd-jwt-key -o jsonpath='{.data.jwt-key}' | base64 -d

# Or decode the default value
echo "ZGJUczNLREIzM3ZXZEdHbUp3djdVSkpSd0xRU2FtY1E=" | base64 -d
```

**Decoded Secret:** `dbTs3KDBI33vWdGGmJwv7UJJRwLQSamcQ`

#### 2. Admin Credentials

**Purpose:** Full administrative access to ejabberd
**Secret Name:** `ejabberd-admin`
**Keys:** `admin-user`, `admin-password`
**Default Values:**
- Username: `admin@ejabberd.local`
- Password: `admin123`

**How to get them:**
```bash
# Get admin credentials from Kubernetes
kubectl get secret ejabberd-admin -o jsonpath='{.data.admin-user}' | base64 -d
kubectl get secret ejabberd-admin -o jsonpath='{.data.admin-password}' | base64 -d
```

#### 3. API Service Account

**Purpose:** Dedicated service account for API operations
**Secret Name:** `ejabberd-admin`
**Keys:** `api-user`, `api-password`
**Default Values:**
- Username: `api@ejabberd.local`
- Password: `api-service-password`

**How to get them:**
```bash
# Get API credentials from Kubernetes
kubectl get secret ejabberd-admin -o jsonpath='{.data.api-user}' | base64 -d
kubectl get secret ejabberd-admin -o jsonpath='{.data.api-password}' | base64 -d
```

### Integration Examples

#### Python Service Integration

```python
import requests
import jwt
from datetime import datetime, timedelta

class EjabberdServiceClient:
    def __init__(self, base_url, jwt_secret=None, admin_user=None, admin_password=None):
        self.base_url = base_url
        self.jwt_secret = jwt_secret or "dbTs3KDBI33vWdGGmJwv7UJJRwLQSamcQ"
        self.admin_auth = (admin_user or "admin@ejabberd.local", 
                          admin_password or "admin123")
    
    def generate_jwt(self, user_jid, expiry_minutes=60):
        """Generate JWT token for service-to-service communication"""
        now = datetime.utcnow()
        payload = {
            'jid': user_jid,
            'iat': now,
            'exp': now + timedelta(minutes=expiry_minutes),
            'iss': 'ejabberd-api'
        }
        return jwt.encode(payload, self.jwt_secret, algorithm='HS256')
    
    def send_message_as_service(self, from_jid, to_jid, body):
        """Send message using JWT authentication"""
        token = self.generate_jwt(from_jid)
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
        data = {
            "type": "chat",
            "from": from_jid,
            "to": to_jid,
            "body": body
        }
        response = requests.post(
            f"{self.base_url}/api/send_message",
            json=data,
            headers=headers
        )
        return response.json()

# Usage in your service
client = EjabberdServiceClient("http://ejabberd-service:5280")
client.send_message_as_service(
    "service@ejabberd.local",
    "user@ejabberd.local", 
    "Hello from your service!"
)
```

#### Node.js Service Integration

```javascript
const axios = require('axios');
const jwt = require('jsonwebtoken');

class EjabberdServiceClient {
    constructor(baseUrl, jwtSecret = 'dbTs3KDBI33vWdGGmJwv7UJJRwLQSamcQ') {
        this.baseUrl = baseUrl;
        this.jwtSecret = jwtSecret;
    }

    generateJWT(userJid, expiryMinutes = 60) {
        const now = new Date();
        const payload = {
            jid: userJid,
            iat: Math.floor(now.getTime() / 1000),
            exp: Math.floor(now.getTime() / 1000) + (expiryMinutes * 60),
            iss: 'ejabberd-api'
        };
        return jwt.sign(payload, this.jwtSecret, { algorithm: 'HS256' });
    }

    async sendMessage(fromJid, toJid, body) {
        const token = this.generateJWT(fromJid);
        const headers = {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
        };
        
        const data = {
            type: 'chat',
            from: fromJid,
            to: toJid,
            body: body
        };

        const response = await axios.post(
            `${this.baseUrl}/api/send_message`,
            data,
            { headers }
        );
        return response.data;
    }
}

// Usage in your service
const client = new EjabberdServiceClient('http://ejabberd-service:5280');
await client.sendMessage(
    'service@ejabberd.local',
    'user@ejabberd.local',
    'Hello from your service!'
);
```

#### Kubernetes Secret Integration

**Create a secret for your service:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-service-ejabberd-secrets
type: Opaque
data:
  jwt-secret: ZGJUczNLREIzM3ZXZEdHbUp3djdVSkpSd0xRU2FtY1E=  # base64 encoded
  admin-user: YWRtaW5AZWphYmJlcmQubG9jYWw=  # admin@ejabberd.local
  admin-password: YWRtaW4xMjM=  # admin123
  api-user: YXBpQGVqYWJiZXJkLmxvY2Fs  # api@ejabberd.local
  api-password: YXBpLXNlcnZpY2UtcGFzc3dvcmQ=  # api-service-password
```

**Use in your deployment:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-service
spec:
  template:
    spec:
      containers:
      - name: my-service
        env:
        - name: EJABBERD_JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: my-service-ejabberd-secrets
              key: jwt-secret
        - name: EJABBERD_ADMIN_USER
          valueFrom:
            secretKeyRef:
              name: my-service-ejabberd-secrets
              key: admin-user
        - name: EJABBERD_ADMIN_PASSWORD
          valueFrom:
            secretKeyRef:
              name: my-service-ejabberd-secrets
              key: admin-password
```

### Environment Variables Reference

| Variable | Secret Key | Default Value | Purpose |
|----------|------------|---------------|---------|
| `JWT_SECRET` | `jwt-key` | `dbTs3KDBI33vWdGGmJwv7UJJRwLQSamcQ` | JWT token signing |
| `ADMIN_USER` | `admin-user` | `admin@ejabberd.local` | Admin username |
| `ADMIN_PASSWORD` | `admin-password` | `admin123` | Admin password |
| `API_USER` | `api-user` | `api@ejabberd.local` | API service account |
| `API_PASSWORD` | `api-password` | `api-service-password` | API service password |

### Security Best Practices

1. **Rotate Secrets Regularly:**
   ```bash
   # Generate new JWT secret
   openssl rand -base64 32
   
   # Update the secret
   kubectl patch secret ejabberd-jwt-key -p '{"data":{"jwt-key":"NEW_BASE64_ENCODED_SECRET"}}'
   ```

2. **Use Service-Specific JWT Secrets:**
   ```python
   # Generate service-specific secret
   service_jwt_secret = "your-service-specific-secret"
   
   # Use in your service
   client = EjabberdServiceClient("http://ejabberd:5280", service_jwt_secret)
   ```

3. **Implement Token Expiry:**
   ```python
   # Use short-lived tokens for security
   token = client.generate_jwt("service@ejabberd.local", expiry_minutes=15)
   ```

4. **Monitor API Usage:**
   ```bash
   # Check API access logs
   kubectl logs deployment/ejabberd | grep "HTTP API"
   ```

## 🌐 Proxy Calls to ejabberd

### HTTP API Endpoints

The ejabberd HTTP API is available at `http://<host>:5280/api/` and supports all XMPP operations:

#### **Core Endpoints**

| Endpoint | Method | Description | Auth Required |
|----------|--------|-------------|---------------|
| `/api/status` | POST | Server status | Admin/User |
| `/api/register` | POST | Register new user | Admin only |
| `/api/send_message` | POST | Send message | User |
| `/api/get_roster` | POST | Get contact list | User |
| `/api/set_presence` | POST | Set user presence | User |

#### **MUC (Multi-User Chat) Endpoints**

| Endpoint | Method | Description | Auth Required |
|----------|--------|-------------|---------------|
| `/api/create_room` | POST | Create MUC room | Admin |
| `/api/destroy_room` | POST | Delete MUC room | Admin |
| `/api/muc_online_rooms` | POST | List active rooms | Admin/User |
| `/api/get_room_occupants` | POST | Get room users | Admin/User |
| `/api/join_room` | POST | Join room | User |
| `/api/leave_room` | POST | Leave room | User |

### Python Client Library

```python
import requests
import jwt
from datetime import datetime, timedelta

class EjabberdAPI:
    def __init__(self, base_url="http://localhost:5280", 
                 admin_user="admin@ejabberd.local", admin_pass="admin123"):
        self.base_url = base_url
        self.admin_auth = (admin_user, admin_pass)
        self.jwt_secret = "dbTs3KDBI33vWdGGmJwv7UJJRwLQSamcQ"
    
    def generate_jwt(self, user_jid, expiry_minutes=60):
        """Generate JWT token for user"""
        now = datetime.utcnow()
        payload = {
            'jid': user_jid,
            'iat': now,
            'exp': now + timedelta(minutes=expiry_minutes),
            'iss': 'ejabberd-api'
        }
        return jwt.encode(payload, self.jwt_secret, algorithm='HS256')
    
    def api_call(self, endpoint, data=None, auth_type="basic", user_jid=None, user_pass=None):
        """Make API call with different authentication methods"""
        url = f"{self.base_url}/api/{endpoint}"
        headers = {"Content-Type": "application/json"}
        
        if auth_type == "basic":
            if user_jid and user_pass:
                auth = (user_jid, user_pass)
            else:
                auth = self.admin_auth
            response = requests.post(url, json=data or {}, auth=auth, headers=headers)
        
        elif auth_type == "jwt":
            if not user_jid:
                raise ValueError("user_jid required for JWT auth")
            token = self.generate_jwt(user_jid)
            headers["Authorization"] = f"Bearer {token}"
            response = requests.post(url, json=data or {}, headers=headers)
        
        return response
    
    # User Management
    def register_user(self, username, password):
        """Register new user (admin only)"""
        data = {
            "user": username,
            "host": "ejabberd.local",
            "password": password
        }
        return self.api_call("register", data)
    
    def check_user_exists(self, username):
        """Check if user exists"""
        data = {
            "user": username,
            "host": "ejabberd.local"
        }
        return self.api_call("check_account", data)
    
    # Messaging
    def send_message(self, from_jid, to_jid, body, msg_type="chat", auth_type="basic", password=None):
        """Send message"""
        data = {
            "type": msg_type,
            "from": from_jid,
            "to": to_jid,
            "body": body
        }
        return self.api_call("send_message", data, auth_type, from_jid, password)
    
    def send_room_message(self, from_jid, room_name, body, password=None):
        """Send message to MUC room"""
        room_jid = f"{room_name}@conference.ejabberd.local"
        return self.send_message(from_jid, room_jid, body, "groupchat", "basic", password)
    
    # Room Management
    def create_room(self, room_name):
        """Create MUC room (admin only)"""
        data = {
            "name": room_name,
            "service": "conference.ejabberd.local",
            "host": "ejabberd.local"
        }
        return self.api_call("create_room", data)
    
    def list_rooms(self):
        """List online rooms"""
        data = {"service": "conference.ejabberd.local"}
        return self.api_call("muc_online_rooms", data)
    
    def get_room_occupants(self, room_name):
        """Get room occupants"""
        data = {
            "name": room_name,
            "service": "conference.ejabberd.local"
        }
        return self.api_call("get_room_occupants", data)
    
    # Presence Management
    def set_presence(self, user_jid, password, show="chat", status="Available"):
        """Set user presence"""
        user, host = user_jid.split("@")
        data = {
            "user": user,
            "host": host,
            "resource": "api",
            "type": "available",
            "show": show,
            "status": status,
            "priority": "5"
        }
        return self.api_call("set_presence", data, "basic", user_jid, password)
    
    # Server Status
    def get_online_users(self):
        """Get list of online users"""
        data = {"host": "ejabberd.local"}
        return self.api_call("connected_users", data)
    
    def get_server_status(self):
        """Get server status"""
        return self.api_call("status")

# Usage Examples
api = EjabberdAPI()

# 1. Register users
api.register_user("alice", "alice123")
api.register_user("bob", "bob123")

# 2. Create room
api.create_room("general")

# 3. Send messages (Basic Auth)
api.send_message("alice@ejabberd.local", "bob@ejabberd.local", "Hello Bob!", auth_type="basic", password="alice123")
api.send_room_message("alice@ejabberd.local", "general", "Hello everyone!", "alice123")

# 4. Send messages (JWT Auth)
api.send_message("alice@ejabberd.local", "bob@ejabberd.local", "Hello via JWT!", auth_type="jwt")

# 5. Set presence
api.set_presence("alice@ejabberd.local", "alice123", "chat", "Ready to chat!")

# 6. Get server info
status = api.get_server_status()
online_users = api.get_online_users()
```

### Node.js Client Library

```javascript
const axios = require('axios');
const jwt = require('jsonwebtoken');

class EjabberdAPI {
    constructor(baseUrl = 'http://localhost:5280', adminUser = 'admin@ejabberd.local', adminPass = 'admin123') {
        this.baseUrl = baseUrl;
        this.adminAuth = { username: adminUser, password: adminPass };
        this.jwtSecret = 'dbTs3KDBI33vWdGGmJwv7UJJRwLQSamcQ';
    }

    generateJWT(userJid, expiryMinutes = 60) {
        const now = new Date();
        const payload = {
            jid: userJid,
            iat: Math.floor(now.getTime() / 1000),
            exp: Math.floor(now.getTime() / 1000) + (expiryMinutes * 60),
            iss: 'ejabberd-api'
        };
        return jwt.sign(payload, this.jwtSecret, { algorithm: 'HS256' });
    }

    async apiCall(endpoint, data = null, authType = 'basic', userJid = null, userPass = null) {
        const url = `${this.baseUrl}/api/${endpoint}`;
        const headers = { 'Content-Type': 'application/json' };

        let config = { headers };

        if (authType === 'basic') {
            const auth = userJid && userPass ? 
                { username: userJid, password: userPass } : 
                this.adminAuth;
            config.auth = auth;
        } else if (authType === 'jwt') {
            if (!userJid) throw new Error('userJid required for JWT auth');
            const token = this.generateJWT(userJid);
            headers.Authorization = `Bearer ${token}`;
        }

        const response = await axios.post(url, data, config);
        return response.data;
    }

    // User Management
    async registerUser(username, password) {
        return this.apiCall('register', {
            user: username,
            host: 'ejabberd.local',
            password: password
        });
    }

    // Messaging
    async sendMessage(fromJid, toJid, body, msgType = 'chat', authType = 'basic', password = null) {
        return this.apiCall('send_message', {
            type: msgType,
            from: fromJid,
            to: toJid,
            body: body
        }, authType, fromJid, password);
    }

    // Room Management
    async createRoom(roomName) {
        return this.apiCall('create_room', {
            name: roomName,
            service: 'conference.ejabberd.local',
            host: 'ejabberd.local'
        });
    }

    async listRooms() {
        return this.apiCall('muc_online_rooms', {
            service: 'conference.ejabberd.local'
        });
    }
}

// Usage
const api = new EjabberdAPI();

// Register users
await api.registerUser('alice', 'alice123');
await api.registerUser('bob', 'bob123');

// Create room
await api.createRoom('general');

// Send messages
await api.sendMessage('alice@ejabberd.local', 'bob@ejabberd.local', 'Hello Bob!', 'chat', 'basic', 'alice123');
await api.sendMessage('alice@ejabberd.local', 'bob@ejabberd.local', 'Hello via JWT!', 'chat', 'jwt');
```

## 📡 Real-time Communication

### WebSocket Support

The HTTP API includes WebSocket support for real-time communication:

```javascript
// Connect to WebSocket
const ws = new WebSocket('ws://localhost:5280/http-bind/');

ws.onopen = function() {
    console.log('Connected to ejabberd');
    
    // Authenticate
    ws.send(JSON.stringify({
        type: 'auth',
        jid: 'alice@ejabberd.local',
        password: 'alice123'
    }));
};

ws.onmessage = function(event) {
    const data = JSON.parse(event.data);
    console.log('Received:', data);
};

// Send message via WebSocket
ws.send(JSON.stringify({
    type: 'message',
    to: 'bob@ejabberd.local',
    body: 'Hello via WebSocket!'
}));
```

### File Upload Support

The deployment includes HTTP file upload support:

```bash
# Upload file
curl -X PUT http://localhost:5280/upload/ \
  -H "Content-Type: application/octet-stream" \
  -d @file.txt

# Send message with file URL
curl -u alice@ejabberd.local:alice123 -X POST http://localhost:5280/api/send_message \
  -H "Content-Type: application/json" \
  -d '{
    "type": "chat",
    "from": "alice@ejabberd.local",
    "to": "bob@ejabberd.local",
    "body": "Check out this file: http://localhost:5280/upload/filename.txt"
  }'
```

## 🧪 Testing

### Hurl Test Suite

The project includes comprehensive Hurl tests for all API endpoints:

```bash
# Run all tests
hurl hurl-tests/*.hurl

# Run specific test
hurl hurl-tests/muc_endpoints.hurl

# Run with verbose output
hurl --verbose hurl-tests/room_file_upload.hurl
```

### Available Test Files

- `muc_endpoints.hurl` - MUC room management tests
- `room_file_upload.hurl` - File upload simulation tests
- `create_room.hurl` - Room creation tests
- `list_rooms.hurl` - Room listing tests
- `status.hurl` - Server status tests

### Python Test Suite

```bash
# Run Python tests
cd ejabberd/tests
python test_jwt_ejabberd.py
python test_muc_admin.py
```

## 🔧 Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `JWT_SECRET` | Auto-generated | JWT signing key |
| `ADMIN_USER` | `admin@ejabberd.local` | Admin username |
| `ADMIN_PASSWORD` | `admin123` | Admin password |
| `EJABBERD_DOMAIN` | `ejabberd.local` | XMPP domain |

### Custom Configuration

Edit `ejabberd/ejabberd-config.yaml` to customize:

```yaml
# Add custom modules
modules:
  mod_custom: {}
  
# Configure external database
database:
  type: "postgresql"
  host: "postgres.example.com"
  port: 5432
  name: "ejabberd"
  user: "ejabberd"
  password: "password"

# Add custom access rules
access_rules:
  custom_rule:
    - allow: admin
    - deny: all
```

### Production Values

Create `values-prod.yaml`:

```yaml
replicaCount: 3
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10

ingress:
  enabled: true
  hosts:
    - host: xmpp.example.com
      paths:
        - path: /
          pathType: Prefix

resources:
  limits:
    cpu: 1000m
    memory: 2Gi
  requests:
    cpu: 500m
    memory: 1Gi
```

## 🔒 Security

### Authentication Best Practices

1. **Use JWT for API calls** - More secure than Basic Auth
2. **Rotate JWT secrets regularly** - Update the secret in Kubernetes
3. **Use HTTPS in production** - Configure TLS certificates
4. **Implement rate limiting** - Add API rate limiting
5. **Use external authentication** - LDAP, OAuth, etc.

### Network Security

```yaml
# Network policies
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ejabberd-network-policy
spec:
  podSelector:
    matchLabels:
      app: ejabberd
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: frontend
    ports:
    - protocol: TCP
      port: 5280
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: database
    ports:
    - protocol: TCP
      port: 5432
```

## 📊 Monitoring

### Health Checks

```bash
# Check server status
curl -u admin@ejabberd.local:admin123 -X POST http://localhost:5280/api/status

# Check online users
curl -u admin@ejabberd.local:admin123 -X POST http://localhost:5280/api/connected_users_number \
  -H "Content-Type: application/json" \
  -d '{"host": "ejabberd.local"}'
```

### Prometheus Metrics

The deployment includes Prometheus metrics endpoints:

```yaml
# Add to values.yaml
serviceMonitor:
  enabled: true
  interval: 30s
  path: /metrics
```

### Logging

```bash
# View logs
kubectl logs -f deployment/ejabberd

# View specific container logs
kubectl logs -f deployment/ejabberd -c ejabberd
```

## 🚀 Deployment Strategies

### Blue-Green Deployment

```bash
# Deploy new version
helm upgrade ejabberd-v2 ./ejabberd --set fullnameOverride=ejabberd-v2

# Switch traffic
kubectl patch svc ejabberd -p '{"spec":{"selector":{"app":"ejabberd-v2"}}}'

# Remove old version
helm uninstall ejabberd
```

### Rolling Update

```bash
# Update with rolling restart
kubectl rollout restart deployment/ejabberd

# Monitor rollout
kubectl rollout status deployment/ejabberd
```

## 🔍 Troubleshooting

### Common Issues

1. **Admin user not created**
   ```bash
   kubectl logs deployment/ejabberd -c create-admin-user
   ```

2. **API not responding**
   ```bash
   kubectl port-forward svc/ejabberd 5280:5280
   curl http://localhost:5280/api/status
   ```

3. **JWT authentication failing**
   ```bash
   kubectl get secret ejabberd-jwt-key -o jsonpath='{.data.jwt-key}' | base64 -d
   ```

### Debug Commands

```bash
# Check pod status
kubectl get pods -l app=ejabberd

# Check service endpoints
kubectl get endpoints ejabberd

# Check configuration
kubectl exec deployment/ejabberd -- cat /opt/ejabberd/conf/ejabberd.yml

# Test API connectivity
curl -v -u admin@ejabberd.local:admin123 http://localhost:5280/api/status
```

## 📚 API Reference

### Complete Endpoint List

| Endpoint | Method | Description | Auth |
|----------|--------|-------------|------|
| `register` | POST | Register user | Admin |
| `unregister` | POST | Delete user | Admin |
| `send_message` | POST | Send message | User |
| `get_roster` | POST | Get contacts | User |
| `add_rosteritem` | POST | Add contact | User |
| `delete_rosteritem` | POST | Remove contact | User |
| `set_presence` | POST | Set presence | User |
| `get_presence` | POST | Get presence | User |
| `create_room` | POST | Create MUC room | Admin |
| `destroy_room` | POST | Delete MUC room | Admin |
| `muc_online_rooms` | POST | List rooms | Admin/User |
| `get_room_occupants` | POST | Get room users | Admin/User |
| `join_room` | POST | Join room | User |
| `leave_room` | POST | Leave room | User |
| `connected_users` | POST | List online users | Admin/User |
| `connected_users_number` | POST | Count online users | Admin/User |
| `status` | POST | Server status | Admin/User |

### Message Types

- `chat` - Direct message
- `groupchat` - Room message
- `headline` - Broadcast message
- `normal` - Regular message

### Presence Types

- `chat` - Available
- `away` - Away
- `xa` - Extended away
- `dnd` - Do not disturb

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and test with `skaffold dev`
4. Run tests: `hurl hurl-tests/*.hurl`
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

- **Documentation**: [ejabberd Docs](https://docs.ejabberd.im/)
- **Issues**: Create an issue on GitHub
- **Community**: [ejabberd Community](https://www.ejabberd.im/community) 