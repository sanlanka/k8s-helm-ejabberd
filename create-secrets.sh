#!/bin/bash

# Generate a secure admin password
ADMIN_PASSWORD=$(openssl rand -base64 32)

# Generate a secure JWT key
JWT_KEY=$(openssl rand -base64 64)

echo "Creating Kubernetes secrets for ejabberd..."

# Create admin secret
kubectl create secret generic ejabberd-admin-secret \
  --from-literal=admin-password="$ADMIN_PASSWORD" \
  --dry-run=client -o yaml | kubectl apply -f -

# Create JWT secret
kubectl create secret generic jwt-secret \
  --from-literal=jwt-key="$JWT_KEY" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Secrets created successfully!"
echo ""
echo "📋 Secret Details:"
echo "Admin Password: $ADMIN_PASSWORD"
echo "JWT Key: $JWT_KEY"
echo ""
echo "🔐 Admin credentials: admin@localhost / $ADMIN_PASSWORD"
echo "🔑 JWT secret is mounted at /jwt-key in the container"
echo ""
echo "📝 To view secrets later:"
echo "kubectl get secret ejabberd-admin-secret -o jsonpath='{.data.admin-password}' | base64 -d"
echo "kubectl get secret jwt-secret -o jsonpath='{.data.jwt-key}' | base64 -d" 