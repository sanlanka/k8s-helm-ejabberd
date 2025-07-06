#!/bin/bash

# JWT configuration from values.yaml
JWT_SECRET="cjjkgwWy64_olK22FaABFblB2d-L4kXC2TsTZ4ixxoyMh1wMNhwc3WbWfJsZV6OvVNesd2Xx4PQoOa_YX-g1EyHbNWPzDA8ptAXaBxBUjqtQHN9pEAly4HC9I3h1iQv8yKjj9h-dqCk10Z6aOZ0jxseBR0X-yPqsrzMKAw6_IFTeoEe-hiQwhpPR5XKitN3bJTCo5oZ_EKqRwWQ5pQ0He-Z4Iis2C1j2QlRf_0vWpbw5MsnUW3kEoLvPj2exFLuKKbsImzMeayIfuduQ4WJcgadYWvFlX3SU9mDmXLUWmHBYdTo5ip76uLHB3F3XAHAqeta5oeLqw7vopDPUyZMGMw"
JWT_ISSUER="middleware-app"

if [ $# -lt 1 ]; then
    echo "Usage: $0 <username> [host]"
    exit 1
fi

USERNAME=$1
HOST=${2:-localhost}
JID="${USERNAME}@${HOST}"

# Create JWT payload
NOW=$(date +%s)
EXP=$((NOW + 86400))  # 24 hours from now

PAYLOAD=$(cat <<EOF
{
  "iss": "${JWT_ISSUER}",
  "sub": "${JID}",
  "iat": ${NOW},
  "exp": ${EXP},
  "nbf": ${NOW}
}
EOF
)

# Encode header
HEADER='{"alg":"HS256","typ":"JWT"}'
HEADER_B64=$(echo -n "$HEADER" | base64 | tr -d '=' | tr '/+' '_-')

# Encode payload
PAYLOAD_B64=$(echo -n "$PAYLOAD" | base64 | tr -d '=' | tr '/+' '_-')

# Create signature
SIGNATURE=$(echo -n "${HEADER_B64}.${PAYLOAD_B64}" | openssl dgst -sha256 -hmac "$JWT_SECRET" -binary | base64 | tr -d '=' | tr '/+' '_-')

# Combine to create JWT
JWT_TOKEN="${HEADER_B64}.${PAYLOAD_B64}.${SIGNATURE}"

echo "JWT Token for ${JID}:"
echo "$JWT_TOKEN" 