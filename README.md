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

- **Image**: `processone/ejabberd:25.07`
- **Ports**: 
  - 5222 (XMPP client connections)
  - 5269 (XMPP server-to-server)
  - 5280 (HTTP admin interface)

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

Default credentials (change in production):
- Username: `admin@ejabberd.local`
- Password: `admin123`

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

1. Creating ConfigMaps in `ejabberd/templates/`
2. Mounting them as volumes in the deployment
3. Updating the `values.yaml` with configuration options

## Troubleshooting

### Check Pod Status
```bash
kubectl get pods
kubectl describe pod ejabberd-xxx
kubectl logs ejabberd-xxx
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

## Security Considerations

- Change default admin credentials
- Use external secrets management in production
- Configure TLS certificates
- Set up network policies
- Use external database for production

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes
4. Test with `skaffold dev`
5. Submit a pull request 