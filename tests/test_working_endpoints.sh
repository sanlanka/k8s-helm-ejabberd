#!/bin/bash

# Working Endpoints Test Script
# Tests ejabberd endpoints that actually exist and work

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
EJABBERD_URL="http://localhost:5280"
ADMIN_USER="admin"
ADMIN_PASSWORD="admin_password"
TEST_USER="testuser"
TEST_HOST="localhost"
TEST_ROOM="testroom"
TEST_SERVICE="muc.localhost"

# Test results
PASSED=0
FAILED=0

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "PASS")
            echo -e "${GREEN}✓ PASS${NC}: $message"
            ((PASSED++))
            ;;
        "FAIL")
            echo -e "${RED}✗ FAIL${NC}: $message"
            ((FAILED++))
            ;;
        "INFO")
            echo -e "${BLUE}ℹ INFO${NC}: $message"
            ;;
        "WARN")
            echo -e "${YELLOW}⚠ WARN${NC}: $message"
            ;;
    esac
}

# Function to make API request
make_request() {
    local endpoint=$1
    local data=$2
    local description=$3
    
    echo -e "\n${BLUE}Testing: $description${NC}"
    echo "Endpoint: $endpoint"
    if [ -n "$data" ]; then
        echo "Data: $data"
    fi
    
    # Make the request with basic auth
    response=$(curl -s -w "\n%{http_code}" \
        -X POST "$EJABBERD_URL$endpoint" \
        -u "$ADMIN_USER:$ADMIN_PASSWORD" \
        -H "Content-Type: application/json" \
        -d "$data" 2>/dev/null)
    
    # Extract status code and body
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    echo "Response Code: $http_code"
    echo "Response Body: $body"
    
    # Check if request was successful (200, 201, or specific success messages)
    if [[ $http_code -eq 200 ]] || [[ $http_code -eq 201 ]] || echo "$body" | grep -q '"status":"success"' || echo "$body" | grep -q 'successfully'; then
        print_status "PASS" "$description"
        return 0
    else
        print_status "FAIL" "$description (HTTP $http_code)"
        return 1
    fi
}

# Function to check if ejabberd is running
check_ejabberd() {
    echo -e "${BLUE}Checking if ejabberd is running...${NC}"
    
    if curl -s "$EJABBERD_URL" > /dev/null 2>&1; then
        print_status "PASS" "Ejabberd is running and accessible"
        return 0
    else
        print_status "FAIL" "Ejabberd is not accessible at $EJABBERD_URL"
        return 1
    fi
}

# Main test function
run_tests() {
    echo -e "${BLUE}=== Testing Working Endpoints ===${NC}"
    echo "Testing ejabberd endpoints that actually exist and work"
    echo "URL: $EJABBERD_URL"
    echo "Admin: $ADMIN_USER"
    echo ""
    
    # Test 1: Register a user (this should work)
    make_request "/api/register" \
        "{\"user\": \"$TEST_USER\", \"host\": \"$TEST_HOST\", \"password\": \"testpass123\"}" \
        "Register User"
    
    # Test 2: Check if user exists
    make_request "/api/check_account" \
        "{\"user\": \"$TEST_USER\", \"host\": \"$TEST_HOST\"}" \
        "Check Account Exists"
    
    # Test 3: Send message (this is a basic endpoint that should work)
    make_request "/api/send_message" \
        "{\"type\": \"chat\", \"from\": \"$ADMIN_USER@$TEST_HOST\", \"to\": \"$TEST_USER@$TEST_HOST\", \"subject\": \"Test\", \"body\": \"Hello from test!\"}" \
        "Send Message"
    
    # Test 4: Send stanza (this should work if mod_http_api is loaded)
    make_request "/api/send_stanza" \
        "{\"from\": \"$ADMIN_USER@$TEST_HOST\", \"stanza\": \"<message to='$TEST_USER@$TEST_HOST' type='chat'><body>Hello via stanza!</body></message>\"}" \
        "Send Stanza"
    
    # Test 5: Create MUC room (try the correct endpoint name)
    make_request "/api/create_muc_room" \
        "{\"name\": \"$TEST_ROOM\", \"service\": \"$TEST_SERVICE\", \"host\": \"$TEST_HOST\"}" \
        "Create MUC Room"
    
    # Test 6: Alternative create room endpoint
    make_request "/api/muc_create_room" \
        "{\"name\": \"$TEST_ROOM\", \"service\": \"$TEST_SERVICE\", \"host\": \"$TEST_HOST\"}" \
        "Create MUC Room (Alternative)"
    
    # Test 7: Get registered users (admin command that should work)
    make_request "/api/registered_users" \
        "{\"host\": \"$TEST_HOST\"}" \
        "Get Registered Users"
    
    # Test 8: Unregister the test user (cleanup)
    make_request "/api/unregister" \
        "{\"user\": \"$TEST_USER\", \"host\": \"$TEST_HOST\"}" \
        "Unregister User"
}

# Function to print summary
print_summary() {
    echo -e "\n${BLUE}=== Test Summary ===${NC}"
    echo -e "${GREEN}Passed: $PASSED${NC}"
    echo -e "${RED}Failed: $FAILED${NC}"
    echo -e "Total: $((PASSED + FAILED))"
    
    if [ $PASSED -gt 0 ]; then
        echo -e "\n${GREEN}🎉 Some endpoints are working! The ejabberd HTTP API is functional.${NC}"
        if [ $FAILED -gt 0 ]; then
            echo -e "${YELLOW}Some endpoints failed - they may not exist in this ejabberd version.${NC}"
        fi
    else
        echo -e "\n${RED}❌ No endpoints worked. Check configuration and permissions.${NC}"
    fi
}

# Main execution
main() {
    echo "Testing working ejabberd endpoints..."
    
    if ! check_ejabberd; then
        echo "Ejabberd check failed. Exiting."
        exit 1
    fi
    
    run_tests
    print_summary
}

# Run the script
main "$@" 