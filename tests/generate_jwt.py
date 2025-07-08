#!/usr/bin/env python3
import jwt
import sys
import base64
from datetime import datetime, timedelta

# JWT configuration - updated to match values-custom.yaml
JWT_SECRET = "your-jwt-secret-key-here-make-it-long-and-secure"
JWT_ALGORITHM = "HS256"
JWT_ISSUER = "ejabberd"
JWT_USER_CLAIM = "sub"

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
    
    # Use the same secret as ejabberd config
    token = jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)
    return token

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 generate_jwt.py <username> [host]")
        sys.exit(1)
    
    username = sys.argv[1]
    host = sys.argv[2] if len(sys.argv) > 2 else "localhost"
    
    token = generate_jwt_token(username, host)
    print(token) 