#!/bin/bash

set -e

echo "🚀 Setting up ejabberd and running tests..."
echo "==========================================="

# Install the chart
echo "📦 Installing ejabberd Helm chart..."
helm install my-ejabberd ./ejabberd

# Wait for pod to be ready
echo "⏳ Waiting for ejabberd to start..."
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=ejabberd --timeout=60s || {
    echo "⚠️  Pod not ready yet, checking if API is available..."
}

# Set up port forwarding in background
echo "🔗 Setting up port forwarding..."
kubectl port-forward service/my-ejabberd 5280:5280 >/dev/null 2>&1 &
PORT_FORWARD_PID=$!

# Wait for port forwarding to be ready
sleep 5

# Test if API is accessible
echo "🔍 Testing API connectivity..."
if curl -s -X POST http://localhost:5280/api/status -H "Content-Type: application/json" -d '{}' >/dev/null; then
    echo "✅ API is accessible"
else
    echo "❌ API not accessible, waiting a bit more..."
    sleep 10
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
    echo "   - All 5 tests passed successfully"
    echo ""
    echo "🧹 To clean up, run: ./teardown.sh"
else
    echo ""
    echo "❌ Some tests failed. Check the output above."
    echo "🧹 To clean up, run: ./teardown.sh"
    exit 1
fi

# Clean up port forwarding
kill $PORT_FORWARD_PID 2>/dev/null || true 