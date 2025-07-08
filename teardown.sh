#!/bin/bash

echo "🧹 Tearing down ejabberd deployment..."
echo "======================================"

# Kill any existing port forwarding
echo "🔌 Stopping port forwarding..."
pkill -f "kubectl port-forward.*ejabberd" 2>/dev/null || true

# Uninstall the Helm release
echo "🗑️  Uninstalling Helm release..."
helm uninstall ejabberd 2>/dev/null || {
    echo "ℹ️  No release 'ejabberd' found (already cleaned up)"
}

# Wait for pods to be terminated
echo "⏳ Waiting for pods to terminate..."
kubectl wait --for=delete pod -l app.kubernetes.io/name=ejabberd --timeout=30s 2>/dev/null || true

# Double-check and force delete any remaining pods
REMAINING_PODS=$(kubectl get pods -l app.kubernetes.io/name=ejabberd --no-headers 2>/dev/null | wc -l)
if [ "$REMAINING_PODS" -gt 0 ]; then
    echo "🔨 Force deleting remaining pods..."
    kubectl delete pods -l app.kubernetes.io/name=ejabberd --force --grace-period=0 2>/dev/null || true
fi

# Clean up JWT secret
echo "🔐 Cleaning up JWT secret..."
kubectl delete secret jwt-secret 2>/dev/null || {
    echo "ℹ️  No JWT secret found (already cleaned up)"
}

echo ""
echo "✅ Teardown complete!"
echo "   - Helm release uninstalled"
echo "   - All pods terminated"
echo "   - Port forwarding stopped"
echo ""
echo "🚀 To set up again, run: ./setup-and-test.sh" 