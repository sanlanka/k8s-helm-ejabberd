#!/bin/bash

set -e

echo "🚀 Setting up ejabberd and running tests..."
echo "==========================================="

JWT_SECRET_NAME="jwt-secret"
JWT_SECRET_KEY="jwt-key"
JWT_KEY_PATH="/jwt-key"

# Generate a random JWT key
JWT_KEY_VALUE=$(openssl rand -hex 32)

# Create the secret directly from the generated key
kubectl delete secret $JWT_SECRET_NAME --ignore-not-found
kubectl create secret generic $JWT_SECRET_NAME --from-literal=$JWT_SECRET_KEY="$JWT_KEY_VALUE"

echo "🔐 JWT Configuration:"
echo "   - JWT Secret Key: $JWT_KEY_VALUE"
echo "   - JWT JID Field: jid"
echo ""
echo "📋 MIDDLEWARE CONFIGURATION:"
echo "   Your middleware needs this JWT secret key to generate tokens:"
echo "   $JWT_KEY_VALUE"
echo ""
echo "   Example middleware code:"
echo "   \`\`\`python"
echo "   import jwt"
echo "   payload = {'jid': 'user@localhost'}"
echo "   token = jwt.encode(payload, '$JWT_KEY_VALUE', algorithm='HS256')"
echo "   \`\`\`"
echo ""

# Check if release already exists
if helm list | grep -q "ejabberd"; then
    echo "📦 Upgrading existing ejabberd Helm chart..."
    helm upgrade ejabberd ./ejabberd -f values-custom.yaml
else
    echo "📦 Installing ejabberd Helm chart..."
    helm install ejabberd ./ejabberd -f values-custom.yaml
fi

# Wait for pod to be ready
echo "⏳ Waiting for ejabberd to start..."
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=ejabberd --timeout=180s || {
    echo "⚠️  Pod not ready yet, checking if API is available..."
}

# Kill any existing port-forward processes
echo "🔗 Setting up port forwarding..."
pkill -f "kubectl port-forward" || true
sleep 2

# Set up port forwarding in background (using internal service port 5280)
kubectl port-forward service/ejabberd-internal 5280:5280 >/dev/null 2>&1 &
PORT_FORWARD_PID=$!

# Wait for port forwarding to be ready
echo "⏳ Waiting for port forwarding to be ready..."
sleep 10

# Test if API is accessible with retries
echo "🔍 Testing API connectivity..."
MAX_RETRIES=5
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -s -X POST http://localhost:5280/api/status -H "Content-Type: application/json" -d '{}' >/dev/null 2>&1; then
        echo "✅ API is accessible"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        echo "❌ API not accessible (attempt $RETRY_COUNT/$MAX_RETRIES), waiting..."
        sleep 5
    fi
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "❌ API still not accessible after $MAX_RETRIES attempts"
    echo "🔍 Checking pod status..."
    kubectl get pods -l app.kubernetes.io/name=ejabberd
    echo "🔍 Checking pod logs..."
    kubectl logs -l app.kubernetes.io/name=ejabberd --tail=20
    exit 1
fi

# Run the tests
echo "🧪 Running tests..."
if hurl --variables-file tests/vars.env --test --jobs 1 tests/*.hurl; then
    echo ""
    echo "🎉 All tests passed! ejabberd is working correctly."
    echo ""
    echo "📋 Summary:"
    echo "   - ejabberd is deployed and running"
    echo "   - API is accessible on port 5280"
    echo "   - All tests passed successfully"
    echo ""
    echo "🔐 JWT Configuration:"
    echo "   - JWT Authentication: ENABLED"
    echo "   - JWT Secret Key: $JWT_KEY_VALUE"
    echo "   - JWT JID Field: jid"
    echo ""
    echo "🌐 ejabberd is now accessible at: http://localhost:5280"
    echo "🔗 Port-forwarding is running in background (PID: $PORT_FORWARD_PID)"
    echo "🧹 To clean up, run: ./teardown.sh"
    echo "🛑 To stop port-forwarding: kill $PORT_FORWARD_PID"
else
    echo ""
    echo "❌ Some tests failed. Check the output above."
    echo ""
    echo "🔐 JWT Configuration:"
    echo "   - JWT Authentication: ENABLED"
    echo "   - JWT Secret Key: $JWT_KEY_VALUE"
    echo "   - JWT JID Field: jid"
    echo ""
    echo "🧹 To clean up, run: ./teardown.sh"
    exit 1
fi

# Note: Port-forwarding is kept running for continued access
echo ""
echo "💡 Port-forwarding is still active. You can access ejabberd at http://localhost:5280"
echo "   To stop it later, run: kill $PORT_FORWARD_PID" 