#!/bin/bash

# JWT Token Test Script
# This script tests JWT token generation and validation

echo "🔐 Testing JWT Token Generation and Validation"
echo "=============================================="

# Check if Python and JWT library are available
if ! python3 -c "import jwt" 2>/dev/null; then
    echo "❌ JWT library not found. Installing..."
    pip3 install PyJWT
fi

# Generate a JWT token
echo "📝 Generating JWT token for test user..."
TOKEN=$(python3 tests/generate_jwt.py "jwt-test-user" "localhost")

if [ $? -eq 0 ]; then
    echo "✅ JWT token generated successfully"
    echo "🔑 Token: ${TOKEN:0:50}..."
    
    # Test token structure (basic validation)
    echo "🔍 Validating token structure..."
    
    # Decode token header (without verification)
    HEADER=$(echo $TOKEN | cut -d'.' -f1 | base64 -d 2>/dev/null | python3 -c "import sys, json; print(json.dumps(json.load(sys.stdin), indent=2))" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo "✅ Token header is valid JSON"
        echo "📋 Header: $HEADER"
    else
        echo "❌ Token header validation failed"
    fi
    
    # Test token payload (without verification)
    PAYLOAD=$(echo $TOKEN | cut -d'.' -f2 | base64 -d 2>/dev/null | python3 -c "import sys, json; print(json.dumps(json.load(sys.stdin), indent=2))" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo "✅ Token payload is valid JSON"
        echo "📋 Payload: $PAYLOAD"
        
        # Check if payload contains required fields
        if echo "$PAYLOAD" | grep -q '"sub"'; then
            echo "✅ Token contains 'sub' claim"
        else
            echo "❌ Token missing 'sub' claim"
        fi
        
        if echo "$PAYLOAD" | grep -q '"iss"'; then
            echo "✅ Token contains 'iss' claim"
        else
            echo "❌ Token missing 'iss' claim"
        fi
        
        if echo "$PAYLOAD" | grep -q '"exp"'; then
            echo "✅ Token contains 'exp' claim"
        else
            echo "❌ Token missing 'exp' claim"
        fi
    else
        echo "❌ Token payload validation failed"
    fi
    
else
    echo "❌ Failed to generate JWT token"
    exit 1
fi

echo ""
echo "🎉 JWT token test completed!"
echo ""
echo "📝 Next steps for full JWT testing:"
echo "   1. Deploy ejabberd with JWT configuration"
echo "   2. Use the generated token for XMPP authentication"
echo "   3. Verify authentication succeeds"
echo ""
echo "🔑 Generated token: $TOKEN" 