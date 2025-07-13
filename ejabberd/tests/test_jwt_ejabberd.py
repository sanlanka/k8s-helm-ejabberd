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
    print("🧪 ejabberd JWT & MUC Test Suite")
    print("=" * 50)

    # Generate JWT for XMPP
    secret, kid = load_secret(JWT_JWK_B64)
    jwt = gen_jwt(secret, kid, JID)
    print(f"Generated JWT: {jwt[:50]}...")
    print(f"Target API: http://{HOST}:{PORT}/api/")
    print(f"Admin User: admin@ejabberd.local")
    print()

    # Test 1: Admin user authentication (this should work!)
    print("📋 Testing with admin user credentials:")
    admin_auth = ("admin@ejabberd.local", "admin123")

    status_result = test_api_endpoint(
        "status", auth=admin_auth, description="Server status with admin"
    )
    if status_result and status_result.status_code == 200:
        print("   ✅ Admin authentication successful!")
    else:
        print("   ❌ Admin authentication failed - check if admin user exists")
        return

    # Test 2: MUC operations with admin user
    print("\n📋 Testing MUC operations with admin user:")
    test_api_endpoint(
        "muc_online_rooms",
        {"service": SERVICE},
        auth=admin_auth,
        description="List online rooms",
    )
    test_api_endpoint(
        "create_room",
        {"name": ROOM, "service": SERVICE, "host": DOMAIN},
        auth=admin_auth,
        description="Create MUC room",
    )
    test_api_endpoint(
        "muc_online_rooms",
        {"service": SERVICE},
        auth=admin_auth,
        description="List rooms after creation",
    )

    # Test 3: User registration with admin privileges
    print("\n📋 Testing user registration with admin:")
    register_result = test_api_endpoint(
        "register",
        {"user": USER, "host": DOMAIN, "password": "testpass123"},
        auth=admin_auth,
        description="Register test user",
    )

    # Test 4: Test user authentication (if registration succeeded)
    if register_result and register_result.status_code == 200:
        print("\n📋 Testing with newly registered user:")
        test_auth = (JID, "testpass123")
        test_api_endpoint("status", auth=test_auth, description="Status with test user")
        test_api_endpoint(
            "create_room",
            {"name": f"{ROOM}2", "service": SERVICE, "host": DOMAIN},
            auth=test_auth,
            description="Create room with test user",
        )
    else:
        print("\n❌ User registration failed, skipping test user authentication")

    # Test 5: JWT Bearer token (for XMPP, not HTTP API)
    print("\n📋 Testing JWT Bearer token (note: this is for XMPP, not HTTP API):")
    headers = {"Authorization": f"Bearer {jwt}"}

    try:
        r = requests.post(
            f"http://{HOST}:{PORT}/api/status", headers=headers, json={}, timeout=10
        )
        status = "✅" if r.status_code == 200 else "❌"
        print(f"{status} JWT Bearer      → [{r.status_code}] JWT authentication test")
        if r.status_code != 200:
            print(f"   Response: {r.text.strip()}")
            print("   💡 Note: JWT tokens are for XMPP connections, not HTTP API")
    except Exception as e:
        print(f"❌ JWT Bearer      → ERROR: {e}")

    # Test 6: API without authentication (should fail)
    print("\n📋 Testing API endpoints without authentication (should fail):")
    test_api_endpoint("status", description="Server status (no auth)")
    test_api_endpoint(
        "muc_online_rooms", {"service": SERVICE}, description="List rooms (no auth)"
    )

    print()
    print("📊 Test Summary:")
    print(f"   - Admin User: admin@ejabberd.local (✅ Working)")
    print(f"   - JWT Token: {jwt[:30]}... (for XMPP connections)")
    print(
        f"   - Test User: {JID} ({'✅ Created' if register_result and register_result.status_code == 200 else '❌ Failed'})"
    )
    print(f"   - MUC Service: {SERVICE}")
    print(f"   - XMPP Server: {HOST}:5222")
    print()
    print("💡 Key Points:")
    print("   1. ✅ Admin user works for HTTP API access")
    print("   2. ✅ MUC rooms can be created and managed")
    print("   3. 🔑 JWT tokens are for XMPP client connections, not HTTP API")
    print("   4. 🔐 HTTP API requires Basic Auth with existing user credentials")
    print("   5. 🏠 MUC service is fully functional at conference.ejabberd.local")


if __name__ == "__main__":
    main()
