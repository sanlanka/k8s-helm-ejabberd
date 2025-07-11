#!/bin/bash

# Simple test script for ejabberd deployment
set -e

echo "🚀 Testing ejabberd deployment..."

# Check if ejabberd pod is running
echo "📋 Checking pod status..."
kubectl get pods -l app.kubernetes.io/name=ejabberd

# Check if service is available
echo "📋 Checking service status..."
kubectl get svc ejabberd

# Port forward for testing
echo "📋 Setting up port forwarding for testing..."
kubectl port-forward svc/ejabberd 5222:5222 5280:5280 &
PORT_FORWARD_PID=$!

# Wait a moment for port forwarding to establish
sleep 3

# Test XMPP port
echo "📋 Testing XMPP port (5222)..."
nc -z localhost 5222 && echo "✅ XMPP port 5222 is accessible" || echo "❌ XMPP port 5222 is not accessible"

# Test HTTP admin port
echo "📋 Testing HTTP admin port (5280)..."
nc -z localhost 5280 && echo "✅ HTTP admin port 5280 is accessible" || echo "❌ HTTP admin port 5280 is not accessible"

# Test HTTP endpoint if available
echo "📋 Testing HTTP endpoint..."
curl -s http://localhost:5280/ > /dev/null && echo "✅ HTTP endpoint is responsive" || echo "❌ HTTP endpoint is not responsive"

# Clean up port forwarding
kill $PORT_FORWARD_PID 2>/dev/null || true

echo "✅ Basic deployment test completed!"
echo ""
echo "💡 Access the admin interface at http://localhost:5280/admin/"
echo "💡 Default credentials: admin@ejabberd.local / admin123"
echo ""
echo "🔧 To access services locally, run:"
echo "   kubectl port-forward svc/ejabberd 5222:5222 5280:5280" 