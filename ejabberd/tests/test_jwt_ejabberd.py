# test_jwt_ejabberd.py

import os
import base64
import json
import time
import requests
import hmac, hashlib

# Config
JWT_JWK_B64 = os.getenv(
    "JWT_JWK_B64",
    "eyJrdHkiOiJvY3QiLCJrIjoiWjBwYWMyTkxSVUl6TTNaWFpHVkhiVXAzZGpkVlNrcFNkMHhSVTJGdFkxRT0ifQ==",
)
HOST = os.getenv("EJABBERD_API_HOST", "localhost")
PORT = int(os.getenv("EJABBERD_API_PORT", "5280"))
USER = os.getenv("EJABBERD_USER", "test")
DOMAIN = os.getenv("EJABBERD_DOMAIN", "ejabberd.local")
JID = f"{USER}@{DOMAIN}"
ROOM = os.getenv("EJABBERD_ROOM", "room1")
SERVICE = f"conference.{DOMAIN}"


def b64url(data: bytes) -> bytes:
    return base64.urlsafe_b64encode(data).rstrip(b"=")


def load_secret(jwk_b64):
    padded = jwk_b64 + "=" * (-len(jwk_b64) % 4)
    jwk = json.loads(base64.urlsafe_b64decode(padded).decode())
    raw = jwk["k"] + "=" * (-len(jwk["k"]) % 4)
    secret = base64.urlsafe_b64decode(raw)
    return secret, jwk.get("kid")


def gen_jwt(secret, kid, jid, ttl=3600):
    now = int(time.time())
    hdr = {"alg": "HS256", "typ": "JWT"}
    if kid:
        hdr["kid"] = kid
    pl = {"jid": jid, "exp": now + ttl}
    h = b64url(json.dumps(hdr, separators=(",", ":")).encode())
    p = b64url(json.dumps(pl, separators=(",", ":")).encode())
    inp = h + b"." + p
    sig = hmac.new(secret, inp, hashlib.sha256).digest()
    s = b64url(sig)
    return (inp + b"." + s).decode()


def test_api_endpoint(command, payload=None, auth=None, description=""):
    """Test a single API endpoint"""
    url = f"http://{HOST}:{PORT}/api/{command}"
    
    try:
        r = requests.post(url, auth=auth, json=payload or {}, timeout=10)
        status = "✅" if r.status_code == 200 else "❌"
        print(f"{status} {command:15} → [{r.status_code}] {description}")
        if r.status_code != 200:
            print(f"   Response: {r.text.strip()}")
        return r
    except Exception as e:
        print(f"❌ {command:15} → ERROR: {e}")
        return None


def main():
    print("🧪 ejabberd API Test (no admin required)")
    print("=" * 50)
    
    # Generate JWT for XMPP
    secret, kid = load_secret(JWT_JWK_B64)
    jwt = gen_jwt(secret, kid, JID)
    print(f"Generated JWT: {jwt[:50]}...")
    print(f"Target API: http://{HOST}:{PORT}/api/")
    print()

    # Test 1: API without authentication
    print("📋 Testing API endpoints without authentication:")
    test_api_endpoint("status", description="Server status")
    test_api_endpoint("create_room", {"name": ROOM, "service": SERVICE}, description="Create MUC room")
    test_api_endpoint("muc_online_rooms", {"service": SERVICE}, description="List online rooms")
    
    print()
    
    # Test 2: API with JWT Bearer token
    print("📋 Testing API endpoints with JWT Bearer token:")
    headers = {"Authorization": f"Bearer {jwt}"}
    
    try:
        r = requests.post(f"http://{HOST}:{PORT}/api/status", headers=headers, json={}, timeout=10)
        status = "✅" if r.status_code == 200 else "❌"
        print(f"{status} JWT Bearer      → [{r.status_code}] JWT authentication test")
        if r.status_code != 200:
            print(f"   Response: {r.text.strip()}")
    except Exception as e:
        print(f"❌ JWT Bearer      → ERROR: {e}")
    
    print()
    
    # Test 3: Try to register a test user
    print("📋 Testing user registration:")
    test_api_endpoint("register", {
        "user": USER,
        "host": DOMAIN,
        "password": "testpass123"
    }, description="Register test user")
    
    # Test 4: Try with admin user credentials (created by init container)
    print()
    print("📋 Testing with admin user credentials:")
    admin_auth = ("admin@ejabberd.local", "admin123")
    test_api_endpoint("status", auth=admin_auth, description="Status with admin user")
    test_api_endpoint("create_room", {"name": ROOM, "service": SERVICE, "host": DOMAIN}, auth=admin_auth, description="Create room with admin user")
    test_api_endpoint("muc_online_rooms", {"service": SERVICE}, auth=admin_auth, description="List online rooms with admin user")
    
    # Test 5: Try with the test user credentials
    print()
    print("📋 Testing with test user credentials:")
    test_auth = (JID, "testpass123")
    test_api_endpoint("status", auth=test_auth, description="Status with test user")
    test_api_endpoint("create_room", {"name": ROOM, "service": SERVICE}, auth=test_auth, description="Create room with test user")
    
    print()
    print("📋 Summary:")
    print(f"   - JWT Token: {jwt[:30]}...")
    print(f"   - Test User: {JID}")
    print(f"   - MUC Service: {SERVICE}")
    print(f"   - XMPP Server: {HOST}:5222")
    print()
    print("💡 Next steps:")
    print("   1. If registration works, use test user credentials for API calls")
    print("   2. Use JWT token for XMPP client connections")
    print("   3. Test MUC room creation and messaging")


if __name__ == "__main__":
    main()
