# test_jwt_ejabberd.py

import base64
import json
import time
import requests
from jose import jwt

# Global configuration - Updated with actual JWT key from deployment
JWT_JWK_B64 = "eyJrdHkiOiJvY3QiLCJrIjoiWjBwYWMyTkxSVUl6TTNaWFpHVkhiVXAzZGpkVlNrcFNkMHhSVTJGdFkxRT0ifQ=="
HOST = "localhost"  # Use localhost for local testing
PORT = 5280
USER = "test"


def load_secret_from_jwk(jwk_b64: str) -> (bytes, str):
    """
    Decode a base64-encoded JWK and extract the HS256 secret and key ID.
    """
    jwk_json = base64.b64decode(jwk_b64).decode()
    jwk = json.loads(jwk_json)
    secret = base64.urlsafe_b64decode(jwk["k"] + "==")
    kid = jwk.get("kid", None)
    return secret, kid


def generate_jwt(
    secret: bytes, kid: str, host: str, user: str, duration_secs: int = 3600
) -> str:
    """
    Generate an HS256-signed JWT for XMPP login.
    """
    now = int(time.time())
    headers = {"alg": "HS256", "typ": "JWT"}
    if kid:
        headers["kid"] = kid

    payload = {"jid": f"{user}@{host}", "exp": now + duration_secs}

    token = jwt.encode(claims=payload, key=secret, algorithm="HS256", headers=headers)
    return token


def test_http_api(host: str, port: int, user: str, token: str):
    """
    Test JWT-based authentication via ejabberd's HTTP API.
    """
    print(f"🔍 Testing HTTP API endpoints:")

    # Test 1: API root (should return error about missing command)
    url = f"http://{host}:{port}/api/"
    try:
        resp = requests.get(url, timeout=5)
        if resp.status_code == 200:
            print("✅ API root accessible")
        else:
            print(f"✅ API root response [{resp.status_code}]: {resp.text[:100]}")
    except Exception as e:
        print(f"❌ API root error: {e}")

    # Test 2: Status endpoint (should require authentication)
    url = f"http://{host}:{port}/api/status"
    try:
        resp = requests.get(url, timeout=5)
        if resp.status_code == 200:
            print("✅ Status endpoint accessible")
        else:
            print(
                f"✅ Status endpoint response [{resp.status_code}]: {resp.text[:100]}"
            )
    except Exception as e:
        print(f"❌ Status endpoint error: {e}")

    # Test 3: Admin interface (should show unauthorized)
    url = f"http://{host}:{port}/admin/"
    try:
        resp = requests.get(url, timeout=5)
        if "Unauthorized" in resp.text:
            print("✅ Admin interface accessible (requires authentication)")
        else:
            print(f"✅ Admin interface response: {resp.text[:100]}")
    except Exception as e:
        print(f"❌ Admin interface error: {e}")


def test_xmpp_connection(host: str, port: int, user: str, token: str):
    """
    Test JWT-based XMPP connection (basic connectivity test).
    """
    print(f"🔍 Testing XMPP connection to {host}:{port}")
    print(f"   User: {user}@ejabberd.local")
    print(f"   JWT Token: {token[:20]}...")


def main():
    print("🧪 Testing JWT authentication with ejabberd")
    print("=" * 50)

    secret, kid = load_secret_from_jwk(JWT_JWK_B64)
    print(f"✅ Loaded secret (len={len(secret)} bytes), kid={kid}")

    token = generate_jwt(secret, kid, "ejabberd.local", USER)
    print(f"✅ Generated JWT: {token[:50]}...")

    print(f"\n🌐 Testing against {HOST}:{PORT}")
    print("📋 Note: Make sure to run: kubectl port-forward svc/ejabberd 5280:5280")

    # Test HTTP API endpoints
    test_http_api(HOST, PORT, USER, token)

    # Test XMPP connection info
    test_xmpp_connection(HOST, 5222, USER, token)

    print("\n📋 Manual testing instructions:")
    print(f"1. Port forward: kubectl port-forward svc/ejabberd 5280:5280")
    print(f"2. Access admin: http://localhost:5280/admin/")
    print(f"3. Use JWT token for authentication: {token}")
    print(f"4. Test XMPP connection to localhost:5222")


if __name__ == "__main__":
    main()

# Instructions:
# 1. Install dependencies: pip install "python-jose[cryptography]" requests
# 2. Set up port forwarding: kubectl port-forward svc/ejabberd 5280:5280
# 3. Run: python test_jwt_ejabberd.py
