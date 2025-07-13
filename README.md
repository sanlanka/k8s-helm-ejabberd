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

The ejabberd HTTP API is available at `http://<your-host>:5280/api/` and requires Basic Authentication using the admin credentials above.

Example API calls:
```bash
# Get server status
curl -u admin@ejabberd.local:admin123 -X POST http://localhost:5280/api/status

# Create a MUC room
curl -u admin@ejabberd.local:admin123 -X POST http://localhost:5280/api/create_room \
  -H "Content-Type: application/json" \
  -d '{"name": "general", "service": "conference.ejabberd.local", "host": "ejabberd.local"}'

# List online MUC rooms
curl -u admin@ejabberd.local:admin123 -X POST http://localhost:5280/api/muc_online_rooms \
  -H "Content-Type: application/json" \
  -d '{"service": "conference.ejabberd.local"}'
```

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