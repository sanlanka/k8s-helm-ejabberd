#!/bin/bash

# ejabberd Hurl Test Runner
# This script runs all Hurl tests against the ejabberd deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VARIABLES_FILE="${SCRIPT_DIR}/variables.env"
TEST_DIR="${SCRIPT_DIR}"
LOG_DIR="${SCRIPT_DIR}/logs"

# Create logs directory
mkdir -p "${LOG_DIR}"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if hurl is installed
if ! command -v hurl &> /dev/null; then
    print_error "Hurl is not installed. Please install it first:"
    echo "  brew install hurl  (macOS)"
    echo "  apt install hurl   (Ubuntu/Debian)"
    echo "  Or visit: https://github.com/Orange-OpenSource/hurl"
    exit 1
fi

# Check if variables file exists
if [ ! -f "${VARIABLES_FILE}" ]; then
    print_error "Variables file not found: ${VARIABLES_FILE}"
    print_warning "Please create and configure the variables.env file"
    exit 1
fi

print_status "Starting ejabberd API tests with Hurl..."
print_status "Using variables from: ${VARIABLES_FILE}"

# List of test files in order
TEST_FILES=(
    "01-health-check.hurl"
    "02-jwt-authentication.hurl"
    "03-user-management.hurl"
    "04-presence-status.hurl"
    "04-xmpp-messaging.hurl"
    "05-vcard-profiles.hurl"
    "05-muc-groupchat.hurl"
    "06-message-archive.hurl"
    "07-offline-messages.hurl"
    "08-privacy-blocking.hurl"
    "09-push-advanced.hurl"
)

# Track test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run a single test file
run_test() {
    local test_file="$1"
    local log_file="${LOG_DIR}/${test_file%.hurl}.log"
    
    print_status "Running test: ${test_file}"
    
    if hurl --variables-file "${VARIABLES_FILE}" \
            --test \
            --report-html "${LOG_DIR}" \
            "${TEST_DIR}/${test_file}" > "${log_file}" 2>&1; then
        print_status "✅ PASSED: ${test_file}"
        ((PASSED_TESTS++))
    else
        print_error "❌ FAILED: ${test_file}"
        print_warning "Check log file: ${log_file}"
        # Show last few lines of the log for immediate feedback
        echo "Last 10 lines of ${test_file} log:"
        tail -n 10 "${log_file}" | sed 's/^/  /'
        ((FAILED_TESTS++))
    fi
    
    ((TOTAL_TESTS++))
}

# Function to run all tests
run_all_tests() {
    print_status "Running all ejabberd tests..."
    
    for test_file in "${TEST_FILES[@]}"; do
        if [ -f "${TEST_DIR}/${test_file}" ]; then
            run_test "${test_file}"
        else
            print_warning "Test file not found: ${test_file}"
        fi
        echo  # Add blank line between tests
    done
}

# Function to run a specific test
run_specific_test() {
    local test_name="$1"
    local test_file="${test_name}"
    
    # Add .hurl extension if not present
    if [[ ! "${test_file}" == *.hurl ]]; then
        test_file="${test_file}.hurl"
    fi
    
    if [ -f "${TEST_DIR}/${test_file}" ]; then
        run_test "${test_file}"
    else
        print_error "Test file not found: ${test_file}"
        print_warning "Available tests:"
        for file in "${TEST_FILES[@]}"; do
            echo "  - ${file}"
        done
        exit 1
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [TEST_NAME]"
    echo ""
    echo "OPTIONS:"
    echo "  -h, --help     Show this help message"
    echo "  -l, --list     List available tests"
    echo "  -v, --verbose  Enable verbose output"
    echo ""
    echo "TEST_NAME:"
    echo "  Specific test file to run (optional)"
    echo "  If not provided, all tests will be run"
    echo ""
    echo "Examples:"
    echo "  $0                           # Run all tests"
    echo "  $0 01-health-check          # Run specific test"
    echo "  $0 jwt-authentication.hurl  # Run specific test with .hurl extension"
}

# Function to list available tests
list_tests() {
    print_status "Available tests:"
    for test_file in "${TEST_FILES[@]}"; do
        echo "  - ${test_file}"
    done
}

# Parse command line arguments
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -l|--list)
            list_tests
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -*)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
        *)
            # This is a test name
            run_specific_test "$1"
            exit $?
            ;;
    esac
done

# If no specific test was provided, run all tests
run_all_tests

# Print summary
echo ""
print_status "Test Summary:"
echo "  Total tests: ${TOTAL_TESTS}"
echo "  Passed: ${GREEN}${PASSED_TESTS}${NC}"
echo "  Failed: ${RED}${FAILED_TESTS}${NC}"

if [ ${FAILED_TESTS} -eq 0 ]; then
    print_status "🎉 All tests passed!"
    exit 0
else
    print_error "❌ Some tests failed. Check logs in ${LOG_DIR}/"
    exit 1
fi 