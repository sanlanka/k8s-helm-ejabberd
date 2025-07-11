#!/bin/bash

set -e

# Parse command line arguments
USE_HARDCODED=false
HARDCODED_VALUE=""
VALUES_FILE="values-custom.yaml"

while [[ $# -gt 0 ]]; do
    case $1 in
        --hardcoded)
            USE_HARDCODED=true
            HARDCODED_VALUE="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [--hardcoded <secret-value>]"
            echo ""
            echo "Options:"
            echo "  --hardcoded <value>  Use hardcoded JWT secret instead of random generation"
            echo "  --help, -h          Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                           # Use random JWT secret (default)"
            echo "  $0 --hardcoded my-secret    # Use 'my-secret' as hardcoded JWT secret"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "🚀 Setting up ejabberd with JWT authentication..."
echo "================================================"

if [ "$USE_HARDCODED" = true ]; then
    if [ -z "$HARDCODED_VALUE" ]; then
        echo "❌ Error: --hardcoded requires a value"
        echo "Usage: $0 --hardcoded <secret-value>"
        exit 1
    fi
    
    echo "🔐 Using hardcoded JWT secret..."
    JWT_SECRET_VALUE="$HARDCODED_VALUE"
    
    # Update values file to use hardcoded secret
    sed -i.bak 's/useHardcodedSecret: false/useHardcodedSecret: true/' "$VALUES_FILE"
    sed -i.bak "s/hardcodedSecret: \".*\"/hardcodedSecret: \"$HARDCODED_VALUE\"/" "$VALUES_FILE"
    
    echo "🔐 JWT Configuration:"
    echo "   - JWT Secret Key: $JWT_SECRET_VALUE"
    echo "   - JWT JID Field: jid"
    echo "   - Using hardcoded secret"
else
    echo "🔐 Generating random JWT secret..."
    JWT_SECRET_VALUE=$(openssl rand -hex 32)
    
    # Ensure values file uses Kubernetes secret
    sed -i.bak 's/useHardcodedSecret: true/useHardcodedSecret: false/' "$VALUES_FILE"
    
    # Create the JWT secret
    echo "🔐 Creating Kubernetes JWT secret..."
    kubectl delete secret jwt-secret --ignore-not-found
    kubectl create secret generic jwt-secret --from-literal=jwt-key="$JWT_SECRET_VALUE"
    
    echo "🔐 JWT Configuration:"
    echo "   - JWT Secret Key: $JWT_SECRET_VALUE"
    echo "   - JWT JID Field: jid"
    echo "   - Using Kubernetes secret"
fi
echo ""
echo "📋 MIDDLEWARE CONFIGURATION:"
echo "   Your middleware needs this JWT secret key to generate tokens:"
echo "   $JWT_SECRET_VALUE"
echo ""
echo "   Example middleware code:"
echo "   \`\`\`python"
echo "   import jwt"
echo "   payload = {'jid': 'user@localhost'}"
echo "   token = jwt.encode(payload, '$JWT_SECRET_VALUE', algorithm='HS256')"
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

# Run the tests if they exist
if [ -d "tests" ] && ls tests/*.hurl 1> /dev/null 2>&1; then
    echo "🧪 Running tests..."
    
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

    if hurl --variables-file tests/vars.env --test --jobs 1 tests/*.hurl; then
        echo ""
        echo "🎉 All tests passed! ejabberd is working correctly."
    else
        echo ""
        echo "❌ Some tests failed. Check the output above."
        exit 1
    fi
else
    echo "ℹ️  No tests found, skipping test execution."
fi

echo ""
echo "📋 Summary:"
echo "   - ejabberd is deployed and running"
if [ "$USE_HARDCODED" = true ]; then
    echo "   - JWT authentication is enabled with hardcoded secret"
else
    echo "   - JWT authentication is enabled with Kubernetes secret"
fi
echo "   - JWT Secret Key: $JWT_SECRET_VALUE"
echo ""
echo "🌐 ejabberd is now accessible via kubectl port-forward or LoadBalancer"
echo "🧹 To clean up, run: ./teardown.sh"

# Clean up backup files created by sed
rm -f "${VALUES_FILE}.bak" 