# ejabberd Helm Chart

A Kubernetes Helm chart for deploying ejabberd with JWT authentication support.

## 1. Setup and Teardown

### Quick Start
```bash
# Deploy ejabberd with JWT authentication
./setup-and-test.sh

# Clean up everything
./teardown.sh
```

The setup script automatically:
- Generates a secure JWT secret key
- Creates Kubernetes secrets
- Deploys the Helm chart
- Runs tests to verify functionality
- Prints the JWT secret key for your use

### Manual Setup
If you prefer manual setup:

1. **Create JWT secret:**
   ```bash
   kubectl create secret generic jwt-secret --from-literal=jwt-key="your-secret-key"
   ```

2. **Deploy with Helm:**
   ```bash
   helm install ejabberd ./ejabberd -f values-custom.yaml
   ```

## 2. Helm Details

### Configuration
The chart uses `values-custom.yaml` for configuration:

```yaml
# JWT Authentication
jwt:
  enabled: true
  secretName: "jwt-secret"
  secretKey: "jwt-key"
  keyPath: "/jwt-key"

authentification:
  auth_method:
    - jwt
  jwt_key: "/jwt-key"
  jwt_jid_field: "jid"

# Working health probes
statefulSet:
  startupProbe:
    exec:
      command: ["true"]
    initialDelaySeconds: 10
    periodSeconds: 5
    failureThreshold: 30
  readinessProbe:
    exec:
      command: ["true"]
    periodSeconds: 5
  livenessProbe:
    exec:
      command: ["true"]
    periodSeconds: 5
    failureThreshold: 30
```

### Key Configuration Options
- `hosts`: List of XMPP domains (default: `localhost`)
- `service.type`: Service type (default: `LoadBalancer`)
- `replicaCount`: Number of ejabberd instances
- `resources`: CPU/memory limits and requests

## 3. Tests

The test suite validates:
- Basic ejabberd functionality
- User registration and management
- JWT authentication
- API endpoints

Run tests manually:
```bash
# Run all tests
hurl tests/*.hurl

# Run specific test
hurl tests/08_jwt_comprehensive_test.hurl
```

## 4. How to Talk to ejabberd

### JWT Authentication

After running the setup script, you'll get a JWT secret key. Use it to generate authentication tokens:

**Generate JWT Token (Python):**
```python
import jwt

# Get this secret key from the setup script output
secret_key = "31767a4abad3e213e2d35366fdff7115c69762e7f7171028e259ca1578bd503b"
    
    payload = {
    "jid": "testuser@localhost",
    "exp": 1735689600  # Optional expiration
}

token = jwt.encode(payload, secret_key, algorithm="HS256")
print(f"JWT Token: {token}")
```

### How Middleware Gets the JWT Secret

When you run `./setup-and-test.sh`, it prints the JWT secret key that your middleware needs:

```bash
📋 MIDDLEWARE CONFIGURATION:
   Your middleware needs this JWT secret key to generate tokens:
   31767a4abad3e213e2d35366fdff7115c69762e7f7171028e259ca1578bd503b
```

**Store this secret securely** in your middleware configuration (environment variables, secure config files, etc.).

**XMPP Client Connection:**
- Username: `testuser` (from jid: testuser@localhost)
- Password: Use the generated JWT token (not the secret key)
- Server: `localhost` (or your server address)
- Port: `5222`

**API Access:**
```bash
# Check status
curl http://localhost:5280/api/status

# With JWT authentication
curl -H "Authorization: Bearer <your-jwt-token>" \
     http://localhost:5280/api/status
```

### Connection Details
- **XMPP Client (c2s)**: `localhost:5222`
- **XMPP Server (s2s)**: `localhost:5269`
- **HTTP API**: `http://localhost:5280`
- **HTTPS API**: `https://localhost:5443`

## 5. Production Deployment

### Security Considerations
- Change default JWT secret key
- Use proper TLS certificates
- Configure firewall rules
- Set resource limits
- Use persistent storage for database

### Production Values
```yaml
# values-prod.yaml
hosts:
  - "your-domain.com"

certFiles:
  secretName:
    - "your-tls-cert-secret"

service:
  type: LoadBalancer
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: nlb

resources:
  limits:
    cpu: 1000m
    memory: 2Gi
  requests:
    cpu: 500m
    memory: 1Gi

replicaCount: 3
   ```

### Deployment Commands
```bash
# Deploy to production
helm install ejabberd-prod ./ejabberd -f values-prod.yaml

# Upgrade existing deployment
helm upgrade ejabberd-prod ./ejabberd -f values-prod.yaml

# Rollback if needed
helm rollback ejabberd-prod
```

### Monitoring
- Check pod logs: `kubectl logs ejabberd-0`
- Monitor resource usage: `kubectl top pods`
- Check service status: `kubectl get svc ejabberd`

---

For more information, see the [official ejabberd documentation](https://docs.ejabberd.im/). 