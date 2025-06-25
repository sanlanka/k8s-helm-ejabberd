# Deploying ejabberd on GKE

## Prerequisites

1. **GKE Cluster**: Create or use existing GKE cluster
2. **gcloud CLI**: Install and authenticate with `gcloud auth login`
3. **kubectl**: Configure to use your GKE cluster

## Quick Setup

### 1. Connect to GKE Cluster
```bash
# List available clusters
gcloud container clusters list

# Get credentials for your cluster
gcloud container clusters get-credentials YOUR_CLUSTER_NAME --zone YOUR_ZONE

# Verify connection
kubectl cluster-info
```

### 2. Deploy and Test
```bash
# Use the same scripts as local development
./setup-and-test.sh
```

### 3. Access from Internet (Optional)

To expose ejabberd externally, update the service type in `ejabberd/values.yaml`:

```yaml
service:
  type: LoadBalancer  # Instead of ClusterIP
```

Then redeploy:
```bash
helm upgrade my-ejabberd ./ejabberd
```

Get external IP:
```bash
kubectl get service my-ejabberd
```

## Cleanup
```bash
./teardown.sh
```

## Notes

- **Security**: For production, consider using Ingress with SSL/TLS
- **Persistence**: Add persistent volumes for data storage
- **Scaling**: Adjust `replicaCount` in values.yaml for high availability 