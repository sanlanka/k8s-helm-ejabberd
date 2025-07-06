#!/usr/bin/env python3
import jwt
import sys
import base64
from datetime import datetime, timedelta

# JWT configuration - extract from JWK format used in ejabberd
# This is the 'k' value from the JWK in values.yaml
JWT_SECRET_B64URL = "cjjkgwWy64_olK22FaABFblB2d-L4kXC2TsTZ4ixxoyMh1wMNhwc3WbWfJsZV6OvVNesd2Xx4PQoOa_YX-g1EyHbNWPzDA8ptAXaBxBUjqtQHN9pEAly4HC9I3h1iQv8yKjj9h-dqCk10Z6aOZ0jxseBR0X-yPqsrzMKAw6_IFTeoEe-hiQwhpPR5XKitN3bJTCo5oZ_EKqRwWQ5pQ0He-Z4Iis2C1j2QlRf_0vWpbw5MsnUW3kEoLvPj2exFLuKKbsImzMeayIfuduQ4WJcgadYWvFlX3SU9mDmXLUWmHBYdTo5ip76uLHB3F3XAHAqeta5oeLqw7vopDPUyZMGMw"

JWT_ALGORITHM = "HS256"
JWT_ISSUER = "middleware-app"
JWT_USER_CLAIM = "sub"

def base64url_decode(data):
    """Decode base64url-encoded data"""
    # Add padding if needed
    missing_padding = len(data) % 4
    if missing_padding:
        data += '=' * (4 - missing_padding)
    # Replace URL-safe characters
    data = data.replace('-', '+').replace('_', '/')
    return base64.b64decode(data)

def generate_jwt_token(username, host="localhost"):
    """Generate a JWT token for ejabberd authentication"""
    now = datetime.utcnow()
    payload = {
        "iss": JWT_ISSUER,
        "sub": f"{username}@{host}",
        "iat": now,
        "exp": now + timedelta(hours=24),
        "nbf": now
    }
    
    # Use the same secret as ejabberd config (decode from base64url)
    secret_key = base64url_decode(JWT_SECRET_B64URL)
    
    token = jwt.encode(payload, secret_key, algorithm=JWT_ALGORITHM)
    return token

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 generate_jwt.py <username> [host]")
        sys.exit(1)
    
    username = sys.argv[1]
    host = sys.argv[2] if len(sys.argv) > 2 else "localhost"
    
    token = generate_jwt_token(username, host)
    print(token) 