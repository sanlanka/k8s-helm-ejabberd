#!/bin/bash

# Test runner script for ejabberd Helm deployment tests
# This script runs the comprehensive test suite

set -e

# Default configuration
NAMESPACE=${NAMESPACE:-"default"}
RELEASE_NAME=${RELEASE_NAME:-"ejabberd"}
TIMEOUT=${TIMEOUT:-300}

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  ejabberd Helm Deployment Test Suite${NC}"
echo -e "${BLUE}========================================${NC}"
echo

# Check if test script exists
if [ ! -f "$(dirname "$0")/test-deployment.sh" ]; then
    echo "Error: test-deployment.sh not found in $(dirname "$0")"
    exit 1
fi

# Make test script executable
chmod +x "$(dirname "$0")/test-deployment.sh"

# Export environment variables
export NAMESPACE
export RELEASE_NAME
export TIMEOUT

echo "Configuration:"
echo "  Namespace: $NAMESPACE"
echo "  Release Name: $RELEASE_NAME"
echo "  Timeout: ${TIMEOUT}s"
echo

# Run the tests
echo -e "${BLUE}Starting tests...${NC}"
echo

if "$(dirname "$0")/test-deployment.sh"; then
    echo
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  All tests passed successfully!${NC}"
    echo -e "${GREEN}========================================${NC}"
    exit 0
else
    echo
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}  Some tests failed. Check the output above.${NC}"
    echo -e "${RED}========================================${NC}"
    exit 1
fi 