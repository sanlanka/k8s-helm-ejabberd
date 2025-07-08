# ejabberd Helm Chart with JWT Authentication

A Kubernetes Helm chart for deploying ejabberd XMPP server with comprehensive API testing and JWT authentication support. This project demonstrates a complete XMPP server deployment with modern authentication patterns suitable for mobile applications.

## 🎯 What is this about?

This project provides a production-ready Helm chart for deploying ejabberd XMPP server in Kubernetes with the following features:

- **XMPP Server**: Complete ejabberd server deployment with REST API
- **JWT Authentication**: Modern token-based authentication for mobile apps
- **Test-Driven Development**: Comprehensive test suite using Hurl
- **Kubernetes Native**: Full Helm chart with proper resource management
- **API Testing**: Automated testing of all ejabberd REST endpoints

### Architecture Overview

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│ Mobile App  │───▶│  Middleware  │───▶│  ejabberd   │
│             │    │  (XMPP SDK)  │    │   Server    │
└─────────────┘    └──────────────┘    └─────────────┘
       │                   │                   │
       │                   │                   │
       ▼                   ▼                   ▼
   JWT Token         JWT Validation      User Management
   Generation        & XMPP Auth        & Message Routing
```

## 🚀 How to Spin It Up

### Quick Start (Automated)

**One-command setup and testing:**
```bash
./setup-and-test.sh
```

This script will:
1. Deploy ejabberd using Helm
2. Wait for pods to be ready
3. Set up port forwarding
4. Run all tests sequentially
5. Display results

**One-command cleanup:**
```bash
./teardown.sh
```

### Manual Setup (For Development)

If you prefer manual control:

1. **Deploy ejabberd**:
   ```bash
   helm install my-ejabberd ./ejabberd
   ```

2. **Wait for deployment**:
   ```bash
   kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=ejabberd --timeout=300s
   ```

3. **Set up port forwarding**:
   ```bash
   kubectl port-forward service/my-ejabberd 5280:5280 &
   ```

4. **Run tests**:
   ```bash
   hurl --variables-file tests/vars.env --test --jobs 1 tests/*.hurl
   ```

## 🧪 How to Test It

### Test Suite Overview

The test suite verifies all ejabberd functionality:

```bash
tests/
├── 01_status.hurl              # Server health check
├── 02_register_user.hurl       # User registration
├── 03_check_account_exists.hurl # User existence verification
├── 04_unregister_user.hurl     # User deletion
├── 05_check_account_does_not_exist.hurl # Deletion verification
└── 06_jwt_auth_test.hurl       # JWT authentication (when enabled)
```

### Running Tests

**Sequential execution (recommended):**
```bash
hurl --variables-file tests/vars.env --test --jobs 1 tests/*.hurl
```

**Individual test:**
```bash
hurl --variables-file tests/vars.env --test tests/01_status.hurl
```

**Note**: Use `--jobs 1` to run tests sequentially (required for test dependencies).

### Test Examples

**Server Status Check:**
```hurl
GET {{ejabberd_api_url}}/api/status
HTTP 200
[Asserts]
body contains "started"
```

**User Registration:**
```hurl
POST {{ejabberd_api_url}}/api/register
Content-Type: application/json

{
  "user": "testuser",
  "host": "localhost",
  "password": "testpass123"
}

HTTP 200
```

## 🔐 JWT Authentication with ejabberd

This chart supports JWT (JSON Web Token) authentication for XMPP users. JWT is a modern, stateless authentication mechanism.

### Enabling JWT Authentication

1. **Enable JWT in your `values-custom.yaml`:**

```yaml
jwt:
  enabled: true
  secretName: "jwt-secret"
  secretKey: "jwt-key"
  jidField: "sub"
  keyPath: "/opt/ejabberd/jwt-key"

authentification:
  auth_method:
    - jwt
    - mnesia
```

2. **Create the Kubernetes secret for the JWT key:**

By default, the setup script will create a secret named `jwt-secret` with the key `jwt-key` and a default value. To set your own secret:

```bash
kubectl create secret generic jwt-secret --from-literal=jwt-key="your-super-secret-key"
```

If you use the setup script, it will print the default secret value after deployment.

### Generating a JWT Token

You can generate a JWT token for XMPP authentication using Python:

```python
import jwt
payload = {"sub": "testuser@localhost"}
secret = "your-super-secret-key"  # Must match the value in the Kubernetes secret
print(jwt.encode(payload, secret, algorithm="HS256"))
```

### Using the JWT Token for XMPP Authentication

- Use the generated JWT token as the password when connecting with your XMPP client.
- The username/JID should match the `sub` claim in the token (e.g., `testuser@localhost`).
- No password is needed, only the JWT token.

### Example: Authenticating with JWT

```bash
# Register a user (if not already registered)
curl -X POST http://localhost:5280/api/register \
  -H "Content-Type: application/json" \
  -d '{"user": "testuser", "host": "localhost", "password": "irrelevant"}'

# Generate JWT token (Python)
python3 -c 'import jwt; print(jwt.encode({"sub": "testuser@localhost"}, "your-super-secret-key", algorithm="HS256"))'

# Use the token as the password in your XMPP client
```

### JWT Test Example

See `tests/08_jwt_comprehensive_test.hurl` for a test that demonstrates JWT-enabled registration and status checks.

### Default JWT Secret

If you do not provide your own secret, the default is:

```
my-secret-key
```

**Change this in production!**

### Troubleshooting JWT

- If authentication fails, ensure the JWT secret in Kubernetes matches what you use to sign tokens.
- The `sub` claim in the JWT must match the user's JID (e.g., `testuser@localhost`).
- Check pod logs for errors: `kubectl logs -l app.kubernetes.io/name=ejabberd`
- If you change the secret, restart the pods or redeploy the chart.

## 🔐 What is JWT Authentication?

JWT (JSON Web Token) authentication provides a modern, stateless authentication mechanism for XMPP servers. Instead of storing passwords, the system uses cryptographically signed tokens.

### JWT Authentication Flow

```
1. Mobile App ──▶ Middleware: Request authentication
2. Middleware ──▶ JWT Generation: Create token with user claims
3. Middleware ──▶ Mobile App: Return JWT token
4. Mobile App ──▶ ejabberd: Connect with JWT token
5. ejabberd ──▶ JWT Validation: Verify signature & claims
6. ejabberd ──▶ Mobile App: Grant access if valid
```

### JWT Token Structure

```json
{
  "header": {
    "alg": "HS256",
    "typ": "JWT"
  },
  "payload": {
    "sub": "user@localhost",
    "iss": "middleware-app",
    "exp": 1640995200,
    "iat": 1640908800
  },
  "signature": "HMACSHA256(base64UrlEncode(header) + '.' + base64UrlEncode(payload), secret)"
}
```

### JWT Configuration

Enable JWT in `values.yaml`:

```yaml
jwt:
  enabled: true
  secret: |
    {
      "kty": "oct",
      "use": "sig",
      "k": "your-base64-encoded-secret-key",
      "alg": "HS256"
    }
  algorithm: "HS256"
  issuer: "middleware-app"
  userClaim: "sub"
```

## 🧪 How to Test JWT

### JWT Test Example

```hurl
# Test JWT Authentication
POST {{ejabberd_api_url}}/api/status
Content-Type: application/json

{}

HTTP 200
[Asserts]
body contains "started"
```

### JWT Token Generation Example

```python
import jwt
import time
from datetime import datetime, timedelta

def generate_jwt_token(username, domain, secret_key):
    """Generate JWT token for XMPP authentication"""
    
    # Token payload
    payload = {
        'sub': f'{username}@{domain}',  # User JID
        'iss': 'middleware-app',        # Issuer
        'exp': int(time.time()) + 3600, # Expiration (1 hour)
        'iat': int(time.time())         # Issued at
    }
    
    # Generate token
    token = jwt.encode(payload, secret_key, algorithm='HS256')
    return token

# Usage example
secret = "your-secret-key"
token = generate_jwt_token("testuser", "localhost", secret)
print(f"JWT Token: {token}")
```

### XMPP Connection with JWT

```python
import slixmpp

class JWTClient(slixmpp.ClientXMPP):
    def __init__(self, jid, jwt_token):
        super().__init__(jid, None)  # No password needed
        self.jwt_token = jwt_token
        self.add_event_handler("session_start", self.start)
    
    def start(self, event):
        # Use JWT token for authentication
        self.send_presence()
        self.get_roster()
    
    def auth(self, username, password, resource):
        # Override auth to use JWT
        return self.plugin['xep_0078'].auth(username, self.jwt_token, resource)

# Usage
client = JWTClient('testuser@localhost', jwt_token)
client.connect()
client.process()
```

## 📋 Example Code for All Functionality

### 1. Server Status Check

```bash
curl -X GET http://localhost:5280/api/status
```

**Response:**
```json
{
  "status": "started",
  "version": "21.12"
}
```

### 2. User Registration

```bash
curl -X POST http://localhost:5280/api/register \
  -H "Content-Type: application/json" \
  -d '{
    "user": "newuser",
    "host": "localhost",
    "password": "securepass123"
  }'
```

**Response:**
```json
{
  "status": "success"
}
```

### 3. Check User Exists

```bash
curl -X GET "http://localhost:5280/api/registered_users?host=localhost"
```

**Response:**
```json
{
  "users": ["admin", "newuser", "testuser"]
}
```

### 4. Unregister User

```bash
curl -X DELETE http://localhost:5280/api/unregister \
  -H "Content-Type: application/json" \
  -d '{
    "user": "newuser",
    "host": "localhost"
  }'
```

**Response:**
```json
{
  "status": "success"
}
```

### 5. JWT Authentication

```bash
# Generate JWT token (using Python example above)
JWT_TOKEN=$(python3 -c "
import jwt
import time
payload = {
    'sub': 'testuser@localhost',
    'iss': 'middleware-app',
    'exp': int(time.time()) + 3600,
    'iat': int(time.time())
}
print(jwt.encode(payload, 'your-secret-key', algorithm='HS256'))
")

# Use JWT for XMPP authentication
# (Implementation depends on your XMPP client library)
```

## 🔧 Configuration Options

### Basic Configuration

```yaml
# values.yaml
replicaCount: 1
logLevel: info

xmpp:
  domain: localhost

auth:
  adminUser: admin
  adminPassword: "admin_password"
```

### JWT Configuration

```yaml
jwt:
  enabled: true
  secret: |
    {
      "kty": "oct",
      "use": "sig",
      "k": "your-base64-encoded-secret-key",
      "alg": "HS256"
    }
  algorithm: "HS256"
  issuer: "middleware-app"
  userClaim: "sub"
```

### Service Configuration

```yaml
service:
  type: ClusterIP
  port: 5280

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi
```

## 🚨 Troubleshooting

### Common Issues

1. **Port forwarding fails**: Ensure the pod is running
   ```bash
   kubectl get pods -l app.kubernetes.io/name=ejabberd
   ```

2. **Tests fail**: Check pod logs
   ```bash
   kubectl logs -l app.kubernetes.io/name=ejabberd
   ```

3. **JWT not working**: Verify configuration
   ```bash
   kubectl get configmap my-ejabberd-config -o yaml
   ```

### Debug Commands

```bash
# Check pod status
kubectl get pods

# View pod logs
kubectl logs -f deployment/my-ejabberd

# Check service
kubectl get svc my-ejabberd

# Test API directly
curl http://localhost:5280/api/status
```

## 📚 Additional Resources

- [ejabberd Documentation](https://docs.ejabberd.im/)
- [JWT.io](https://jwt.io/) - JWT token debugger
- [Helm Documentation](https://helm.sh/docs/)
- [Hurl Testing Framework](https://hurl.dev/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details. 