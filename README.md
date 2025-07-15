# ejabberd Kubernetes Helm Chart

A minimal Helm chart for deploying ejabberd XMPP server on Kubernetes with Skaffold integration for local development and CI/CD.

## Prerequisites

- Kubernetes cluster (local or GKE)
- [Helm 3.x](https://helm.sh/docs/intro/install/)
- [Skaffold](https://skaffold.dev/docs/install/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

## Quick Start

### 1. Local Development with Skaffold

For local development with live updates:

```bash
# Start local development
skaffold dev

# Or specify the dev profile explicitly
skaffold dev --profile=dev
```

This will:
- Deploy ejabberd to your local Kubernetes cluster
- Use LoadBalancer service type for easy access
- Watch for changes and redeploy automatically

### 2. Manual Helm Deployment

If you prefer using Helm directly:

```bash
# Install the chart
helm install ejabberd ./ejabberd

# Upgrade the deployment
helm upgrade ejabberd ./ejabberd

# Uninstall
helm uninstall ejabberd
```

### 3. Production Deployment

For production deployment:

```bash
# Deploy to production
skaffold run --profile=prod

# Or with plain Helm
helm upgrade --install ejabberd ./ejabberd -f values-prod.yaml
```

## Configuration

### Basic Configuration

The main configuration is in `ejabberd/values.yaml`:

- **Image**: `processone/ejabberd:latest`
- **Ports**: 
  - 5222 (XMPP client connections)
  - 5269 (XMPP server-to-server)
  - 5280 (HTTP admin interface)

### Kubernetes Secrets

The chart automatically creates two secrets:

1. **JWT Secret** (`ejabberd-jwt-key`):
   - Contains JWT signing key for mod_http_api
   - Automatically generated random key
   - Available as environment variable `JWT_SECRET`

2. **Admin User Secret** (`ejabberd-admin`):
   - Contains admin user credentials
   - Username: `admin@ejabberd.local`
   - Password: `admin123` (configurable in values.yaml)
   - Used by init container to create admin user

```bash
# View the secrets
kubectl get secrets ejabberd-jwt-key ejabberd-admin

# View admin credentials (base64 encoded)
kubectl get secret ejabberd-admin -o yaml
```

### MUC (Multi-User Chat) Configuration

The chart includes full MUC support with the following features:

- **MUC Service**: `conference.ejabberd.local`
- **Access Control**: Anyone can create and join rooms
- **Admin Access**: Admin users can manage all rooms via HTTP API
- **Persistent Rooms**: Rooms persist by default
- **Public Rooms**: Rooms are public and discoverable

Key MUC modules configured:
- `mod_muc`: Core MUC functionality
- `mod_muc_admin`: Admin API for room management

Test MUC functionality:
```bash
# Run the MUC test suite
cd ejabberd/tests
python test_muc_admin.py
```

### ejabberd Configuration File

The chart automatically loads the ejabberd configuration from `ejabberd-config.yaml`. This allows you to use the full power of ejabberd's configuration system as documented at https://docs.ejabberd.im/admin/configuration/.

#### Configuration File Location

The configuration file is always loaded from:
```
ejabberd-config.yaml
```

This file should be in the same directory as your Helm chart and contains the ejabberd YAML configuration.

#### Example Configuration

The `ejabberd-config.yaml` file contains a complete ejabberd configuration:

```yaml
# Custom ejabberd configuration
hosts:
  - "xmpp.example.com"
  - "chat.example.com"

loglevel: info

listen:
  -
    port: 5222
    module: ejabberd_c2s
    max_stanza_size: 262144
    shaper: c2s_shaper
    access: c2s
    starttls_required: true
  -
    port: 5269
    module: ejabberd_s2s_in
    max_stanza_size: 524288
  -
    port: 5280
    module: ejabberd_http
    request_handlers:
      "/admin": ejabberd_web_admin
      "/api": mod_http_api
      "/": ejabberd_http

modules:
  mod_adhoc: {}
  mod_admin_extra: {}
  mod_announce:
    access: announce
  mod_http_api:
    api_key: "your-secure-api-key-here"
  mod_http_upload: {}
  mod_mam:
    assume_mam_usage: true
    default: roster
  mod_muc:
    access:
      - allow
    access_admin:
      - allow: admin
    access_create: muc_create
    access_persistent: muc_create
    access_mam:
      - allow
    default_room_jid: ""
    default_room_options:
      mam: true
      persistent: true
  mod_offline:
    access_max_user_messages: max_user_offline_messages
  mod_ping: {}
  mod_roster:
    versioning: true
  mod_vcard: {}
  mod_version:
    show_os: false

auth_method: internal

access_rules:
  local:
    - allow: local
  c2s:
    - deny: blocked
    - allow
  announce:
    - allow: admin
  configure:
    - allow: admin
  muc_create:
    - allow: local

shaper_rules:
  max_user_sessions: 10
  max_user_offline_messages:
    - 5000: admin
    - 100
  c2s_shaper:
    - none: admin
    - normal
  s2s_shaper: fast
```

#### Customizing the Configuration

To customize the ejabberd configuration:

1. Edit the `ejabberd-config.yaml` file
2. Modify the configuration according to your needs
3. Deploy the chart - it will automatically use your updated configuration

```bash
# Edit the configuration
vim ejabberd-config.yaml

# Deploy with your custom configuration
helm install ejabberd ./ejabberd
```

#### Configuration File Location Inside Container

When deployed, the configuration file is mounted at `/opt/ejabberd/conf/ejabberd.yml` inside the container.

### Production Configuration

Production overrides are in `values-prod.yaml`:

- Increased resource limits
- Horizontal Pod Autoscaling
- Ingress configuration
- External database support

### Custom Values

Create your own values file:

```bash
cp ejabberd/values.yaml values-custom.yaml
# Edit values-custom.yaml with your settings
helm install ejabberd ./ejabberd -f values-custom.yaml
```

## Accessing ejabberd

### Local Development

When using `skaffold dev`, the service will be exposed as LoadBalancer. Get the external IP:

```bash
kubectl get svc ejabberd
```

### Production

Configure your ingress and DNS to point to the cluster.

### Admin Interface

Access the admin interface at `http://<your-host>:5280/admin/`

Default admin credentials (automatically created):
- Username: `admin@ejabberd.local`
- Password: `admin123`

The admin user is automatically created during pod startup via an init container and stored in the ejabberd internal database.

### HTTP API Access

The ejabberd HTTP API is available at `http://<your-host>:5280/api/` and requires Basic Authentication.

**Authentication Credentials:**
- **Admin User**: `admin@ejabberd.local` / `password` (full API access)
- **Regular Users**: `username@ejabberd.local` / `user_password` (limited API access)

## 🚀 **API Integration Guide**

This section provides comprehensive examples for integrating with the ejabberd HTTP API from your applications.

### **1. Room Management**

#### **Create a Room**
```bash
# Admin creates a room
curl -u admin@ejabberd.local:password -X POST http://localhost:5280/api/create_room \
  -H "Content-Type: application/json" \
  -d '{
    "name": "general-chat",
    "service": "conference.ejabberd.local", 
    "host": "ejabberd.local"
  }'
```

```python
# Python example
import requests

def create_room(room_name, admin_user="admin@ejabberd.local", admin_pass="password"):
    """Create a MUC room"""
    url = "http://localhost:5280/api/create_room"
    auth = (admin_user, admin_pass)
    data = {
        "name": room_name,
        "service": "conference.ejabberd.local",
        "host": "ejabberd.local"
    }
    
    response = requests.post(url, json=data, auth=auth)
    return response.status_code == 200
```

#### **List Online Rooms**
```bash
curl -u admin@ejabberd.local:password -X POST http://localhost:5280/api/muc_online_rooms \
  -H "Content-Type: application/json" \
  -d '{"service": "conference.ejabberd.local"}'
```

#### **Get Room Information**
```bash
# Get room occupants
curl -u admin@ejabberd.local:password -X POST http://localhost:5280/api/get_room_occupants \
  -H "Content-Type: application/json" \
  -d '{
    "name": "general-chat",
    "service": "conference.ejabberd.local"
  }'

# Get room options
curl -u admin@ejabberd.local:password -X POST http://localhost:5280/api/get_room_options \
  -H "Content-Type: application/json" \
  -d '{
    "name": "general-chat", 
    "service": "conference.ejabberd.local"
  }'
```

### **2. User Management**

#### **Register New Users**
```bash
# Admin registers a new user
curl -u admin@ejabberd.local:password -X POST http://localhost:5280/api/register \
  -H "Content-Type: application/json" \
  -d '{
    "user": "alice",
    "host": "ejabberd.local",
    "password": "alice123"
  }'
```

```python
def register_user(username, password, admin_user="admin@ejabberd.local", admin_pass="password"):
    """Register a new user"""
    url = "http://localhost:5280/api/register"
    auth = (admin_user, admin_pass)
    data = {
        "user": username,
        "host": "ejabberd.local", 
        "password": password
    }
    
    response = requests.post(url, json=data, auth=auth)
    return response.status_code == 200
```

#### **Get User Information**
```bash
# Check if user exists
curl -u admin@ejabberd.local:password -X POST http://localhost:5280/api/check_account \
  -H "Content-Type: application/json" \
  -d '{
    "user": "alice",
    "host": "ejabberd.local"
  }'
```

### **3. Message Sending**

#### **Send Messages as Admin**
```bash
# Admin sends a message to a room
curl -u admin@ejabberd.local:password -X POST http://localhost:5280/api/send_message \
  -H "Content-Type: application/json" \
  -d '{
    "type": "groupchat",
    "from": "admin@ejabberd.local",
    "to": "general-chat@conference.ejabberd.local",
    "subject": "",
    "body": "Welcome to the chat room!"
  }'

# Admin sends a direct message
curl -u admin@ejabberd.local:password -X POST http://localhost:5280/api/send_message \
  -H "Content-Type: application/json" \
  -d '{
    "type": "chat",
    "from": "admin@ejabberd.local", 
    "to": "alice@ejabberd.local",
    "subject": "",
    "body": "Hello Alice!"
  }'
```

#### **Send Messages as User**
```bash
# User sends a message using their own credentials
curl -u alice@ejabberd.local:alice123 -X POST http://localhost:5280/api/send_message \
  -H "Content-Type: application/json" \
  -d '{
    "type": "groupchat",
    "from": "alice@ejabberd.local",
    "to": "general-chat@conference.ejabberd.local",
    "subject": "",
    "body": "Hello everyone!"
  }'
```

```python
def send_message_as_user(from_user, from_pass, to_jid, message_body, message_type="chat"):
    """Send message as a specific user"""
    url = "http://localhost:5280/api/send_message"
    auth = (from_user, from_pass)
    data = {
        "type": message_type,  # "chat" or "groupchat"
        "from": from_user,
        "to": to_jid,
        "subject": "",
        "body": message_body
    }
    
    response = requests.post(url, json=data, auth=auth)
    return response.status_code == 200

# Examples:
# Send direct message
send_message_as_user("alice@ejabberd.local", "alice123", "bob@ejabberd.local", "Hi Bob!")

# Send room message  
send_message_as_user("alice@ejabberd.local", "alice123", "general@conference.ejabberd.local", "Hello room!", "groupchat")
```

### **4. Presence Management**

#### **Set User Presence**
```bash
# Set user as available
curl -u alice@ejabberd.local:alice123 -X POST http://localhost:5280/api/set_presence \
  -H "Content-Type: application/json" \
  -d '{
    "user": "alice",
    "host": "ejabberd.local",
    "resource": "mobile",
    "type": "available",
    "show": "chat",
    "status": "Ready to chat!",
    "priority": "5"
  }'

# Set user as away
curl -u alice@ejabberd.local:alice123 -X POST http://localhost:5280/api/set_presence \
  -H "Content-Type: application/json" \
  -d '{
    "user": "alice",
    "host": "ejabberd.local", 
    "resource": "mobile",
    "type": "available",
    "show": "away",
    "status": "Be right back",
    "priority": "1"
  }'
```

#### **Get User Presence**
```bash
curl -u alice@ejabberd.local:alice123 -X POST http://localhost:5280/api/get_presence \
  -H "Content-Type: application/json" \
  -d '{
    "user": "bob",
    "server": "ejabberd.local"
  }'
```

```python
def set_user_presence(user_jid, password, show="chat", status="Available", priority="5"):
    """Set user presence"""
    url = "http://localhost:5280/api/set_presence"
    auth = (user_jid, password)
    user, host = user_jid.split("@")
    
    data = {
        "user": user,
        "host": host,
        "resource": "api",
        "type": "available",
        "show": show,  # chat, away, xa, dnd
        "status": status,
        "priority": priority
    }
    
    response = requests.post(url, json=data, auth=auth)
    return response.status_code == 200
```

### **5. Roster (Contact List) Management**

#### **Get User's Roster**
```bash
curl -u alice@ejabberd.local:alice123 -X POST http://localhost:5280/api/get_roster \
  -H "Content-Type: application/json" \
  -d '{
    "user": "alice",
    "server": "ejabberd.local"
  }'
```

#### **Add Contact to Roster**
```bash
curl -u alice@ejabberd.local:alice123 -X POST http://localhost:5280/api/add_rosteritem \
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

### **6. Chat States (Typing Indicators)**

```python
def send_chat_state(from_user, from_pass, to_jid, state):
    """Send chat state (typing indicator)
    
    Args:
        state: 'composing', 'paused', 'active', 'inactive', 'gone'
    """
    url = "http://localhost:5280/api/send_chat_state"
    auth = (from_user, from_pass)
    data = {
        "from": from_user,
        "to": to_jid,
        "state": state
    }
    
    response = requests.post(url, json=data, auth=auth)
    return response.status_code == 200

# Examples:
send_chat_state("alice@ejabberd.local", "alice123", "bob@ejabberd.local", "composing")  # Alice is typing
send_chat_state("alice@ejabberd.local", "alice123", "bob@ejabberd.local", "active")    # Alice stopped typing
```

### **7. Complete Integration Example**

```python
import requests
import time

class EjabberdAPI:
    def __init__(self, base_url="http://localhost:5280", admin_user="admin@ejabberd.local", admin_pass="password"):
        self.base_url = base_url
        self.admin_auth = (admin_user, admin_pass)
    
    def create_user_and_room_demo(self):
        """Complete demo: create users, room, and send messages"""
        
        # 1. Register users
        self.register_user("alice", "alice123")
        self.register_user("bob", "bob123")
        
        # 2. Create a room
        self.create_room("demo-room")
        
        # 3. Set user presence
        self.set_presence("alice@ejabberd.local", "alice123", "chat", "Ready to demo!")
        self.set_presence("bob@ejabberd.local", "bob123", "chat", "Hello world!")
        
        # 4. Send messages as different users
        self.send_message("alice@ejabberd.local", "alice123", 
                         "demo-room@conference.ejabberd.local", 
                         "Welcome to our demo room!", "groupchat")
        
        time.sleep(1)
        
        self.send_message("bob@ejabberd.local", "bob123",
                         "demo-room@conference.ejabberd.local", 
                         "Thanks Alice! Great to be here.", "groupchat")
        
        # 5. Send direct message
        self.send_message("alice@ejabberd.local", "alice123",
                         "bob@ejabberd.local",
                         "Hey Bob, how are you doing?", "chat")
        
        print("✅ Demo completed successfully!")
    
    def register_user(self, username, password):
        response = requests.post(f"{self.base_url}/api/register", 
                               auth=self.admin_auth,
                               json={"user": username, "host": "ejabberd.local", "password": password})
        return response.status_code == 200
    
    def create_room(self, room_name):
        response = requests.post(f"{self.base_url}/api/create_room",
                               auth=self.admin_auth, 
                               json={"name": room_name, "service": "conference.ejabberd.local", "host": "ejabberd.local"})
        return response.status_code == 200
    
    def send_message(self, from_jid, password, to_jid, body, msg_type="chat"):
        response = requests.post(f"{self.base_url}/api/send_message",
                               auth=(from_jid, password),
                               json={"type": msg_type, "from": from_jid, "to": to_jid, "body": body})
        return response.status_code == 200
    
    def set_presence(self, user_jid, password, show="chat", status="Available"):
        user, host = user_jid.split("@")
        response = requests.post(f"{self.base_url}/api/set_presence",
                               auth=(user_jid, password),
                               json={"user": user, "host": host, "resource": "api", 
                                    "type": "available", "show": show, "status": status, "priority": "5"})
        return response.status_code == 200

# Usage:
# api = EjabberdAPI()
# api.create_user_and_room_demo()
```

### **8. Available API Endpoints**

#### **Admin-Only Operations:**
- `status` - Get server status
- `create_room` - Create MUC rooms  
- `register` - Register new users
- `muc_online_rooms` - List active rooms
- `get_room_options` - Get room configuration
- `stats` - Get server statistics

#### **User Operations (with own credentials):**
- `send_message` - Send chat/groupchat messages
- `get_roster` - Get contact list
- `add_rosteritem` - Add contacts
- `delete_rosteritem` - Remove contacts  
- `get_presence` - Get user presence
- `set_presence` - Set own presence
- `get_vcard` - Get user profile
- `set_vcard` - Update user profile
- `send_chat_state` - Send typing indicators
- `get_user_rooms` - Get user's rooms
- `join_room` - Join MUC room
- `leave_room` - Leave MUC room

### **9. Message Types**

- **`chat`** - Direct message between users
- **`groupchat`** - Message in a MUC room
- **`headline`** - Broadcast/announcement message
- **`normal`** - Regular message (like email)

### **10. Presence Types**

- **Show values**: `chat` (available), `away`, `xa` (extended away), `dnd` (do not disturb)
- **Type values**: `available`, `unavailable`, `subscribe`, `subscribed`, `unsubscribe`, `unsubscribed`

This API enables full XMPP functionality including messaging, presence, roster management, and room operations for building chat applications, collaboration tools, and real-time communication systems.

## Skaffold Profiles

### `dev` Profile
- Single replica
- LoadBalancer service
- Suitable for local development

### `prod` Profile  
- Multiple replicas
- ClusterIP service
- Ingress enabled
- Autoscaling enabled
- Uses production values

## CI/CD Pipeline

### GitHub Actions Example

```yaml
name: Deploy ejabberd
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Google Cloud CLI
        uses: google-github-actions/setup-gcloud@v0
        with:
          project_id: ${{ secrets.GCP_PROJECT }}
          service_account_key: ${{ secrets.GCP_SA_KEY }}
          
      - name: Configure kubectl
        run: |
          gcloud container clusters get-credentials your-cluster --zone us-central1-c
          
      - name: Install Skaffold
        run: |
          curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64
          sudo install skaffold /usr/local/bin/
          
      - name: Deploy with Skaffold
        run: skaffold run --profile=prod
```

### Manual CI/CD with Helm

```bash
# Build and push custom image (if needed)
docker build -t gcr.io/your-project/ejabberd:$TAG .
docker push gcr.io/your-project/ejabberd:$TAG

# Deploy with Helm
helm upgrade --install ejabberd ./ejabberd \
  --set image.tag=$TAG \
  -f values-prod.yaml
```

## Customization

### Extending the Image

If you need to customize the ejabberd image:

1. Uncomment the build section in `skaffold.yaml`
2. Modify the `Dockerfile`
3. Skaffold will automatically build and deploy your custom image

### Adding Configurations

Add custom ejabberd configurations by:

1. Editing the `ejabberd-config.yaml` file
2. The configuration is automatically loaded and mounted

## Admin User Bootstrap

The chart includes an init container that automatically creates the admin user during pod startup:

1. **Init Container Process**:
   - Starts ejabberd temporarily
   - Creates admin user with credentials from secret
   - Stops ejabberd cleanly
   - Passes control to main container

2. **Admin User Details**:
   - JID: `admin@ejabberd.local`
   - Password: `admin123` (configurable)
   - Role: Full admin privileges
   - Database: Stored in ejabberd internal database

3. **Troubleshooting Admin Creation**:
```bash
# Check init container logs
kubectl logs <pod-name> -c create-admin-user

# Verify admin user was created
kubectl exec -it <pod-name> -- /opt/ejabberd/bin/ejabberdctl registered_users ejabberd.local
```

## Troubleshooting

### Check Pod Status
```bash
kubectl get pods
kubectl describe pod ejabberd-xxx
kubectl logs ejabberd-xxx

# Check init container logs
kubectl logs ejabberd-xxx -c create-admin-user
```

### Check Services
```bash
kubectl get svc
kubectl describe svc ejabberd
```

### Port Forwarding for Testing
```bash
kubectl port-forward svc/ejabberd 5222:5222
kubectl port-forward svc/ejabberd 5280:5280
```

### Verify Configuration File
```bash
# Check if the ConfigMap was created
kubectl get configmap ejabberd-config

# View the configuration content
kubectl get configmap ejabberd-config -o yaml

# Check if the file is mounted correctly
kubectl exec -it ejabberd-xxx -- cat /opt/ejabberd/conf/ejabberd.yml
```

### Test HTTP API
```bash
# Test API connectivity
curl -u admin@ejabberd.local:admin123 http://localhost:5280/api/status

# Test MUC functionality
curl -u admin@ejabberd.local:admin123 -X POST http://localhost:5280/api/muc_online_rooms \
  -H "Content-Type: application/json" \
  -d '{"service": "conference.ejabberd.local"}'
```

### Check Secrets
```bash
# Verify secrets exist
kubectl get secrets ejabberd-jwt-key ejabberd-admin

# Check secret contents
kubectl get secret ejabberd-admin -o jsonpath='{.data.admin-user}' | base64 -d
kubectl get secret ejabberd-admin -o jsonpath='{.data.admin-password}' | base64 -d
```

## Security Considerations

- **Change default admin credentials**: Update `ejabberd.admin.password` in values.yaml for production
- **Use external secrets management**: Consider using Kubernetes secrets or external secret managers
- **Configure TLS certificates**: Set up proper TLS for XMPP and HTTP endpoints
- **Set up network policies**: Restrict network access to ejabberd services
- **Use external database**: Configure external PostgreSQL/MySQL for production
- **Secure your API keys**: Rotate JWT secrets and API keys regularly
- **Admin user security**: 
  - The admin user is created automatically with internal auth
  - Password is stored in Kubernetes secret `ejabberd-admin`
  - Consider using external authentication providers for production
- **MUC access control**: Review MUC access rules for your use case

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes
4. Test with `skaffold dev`
5. Submit a pull request 