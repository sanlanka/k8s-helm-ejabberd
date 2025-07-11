#!/bin/bash

# Simple health check script for ejabberd deployment
# This script performs basic connectivity tests

set -e

# Configuration
NAMESPACE=${NAMESPACE:-"default"}
RELEASE_NAME=${RELEASE_NAME:-"ejabberd"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if pods are running
check_pods() {
    log_info "Checking pod status..."
    
    PODS=$(kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/name=ejabberd,app.kubernetes.io/instance=$RELEASE_NAME" --output json 2>/dev/null | jq -r '.items[].metadata.name' 2>/dev/null)
    
    if [ -z "$PODS" ]; then
        log_error "No pods found for release '$RELEASE_NAME'"
        return 1
    fi
    
    for pod in $PODS; do
        if [ -n "$pod" ] && [ "$pod" != "null" ]; then
            STATUS=$(kubectl get pod "$pod" -n "$NAMESPACE" --output json 2>/dev/null | jq -r '.status.phase' 2>/dev/null)
            READY=$(kubectl get pod "$pod" -n "$NAMESPACE" --output json 2>/dev/null | jq -r '.status.conditions[] | select(.type == "Ready").status' 2>/dev/null)
            
            if [ "$STATUS" = "Running" ] && [ "$READY" = "True" ]; then
                log_success "Pod $pod is running and ready"
            else
                log_error "Pod $pod is not ready (Status: $STATUS, Ready: $READY)"
                return 1
            fi
        fi
    done
    
    return 0
}

# Check service endpoints
check_service() {
    log_info "Checking service endpoints..."
    
    SERVICE_NAME=$(kubectl get svc -n "$NAMESPACE" -l "app.kubernetes.io/name=ejabberd,app.kubernetes.io/instance=$RELEASE_NAME" --output json 2>/dev/null | jq -r '.items[0].metadata.name' 2>/dev/null)
    
    if [ -z "$SERVICE_NAME" ] || [ "$SERVICE_NAME" = "null" ]; then
        log_error "Service not found for release '$RELEASE_NAME'"
        return 1
    fi
    
    ENDPOINTS=$(kubectl get endpoints "$SERVICE_NAME" -n "$NAMESPACE" --output json 2>/dev/null | jq -r '.subsets[0].addresses | length' 2>/dev/null || echo "0")
    
    if [ "$ENDPOINTS" -gt 0 ]; then
        log_success "Service '$SERVICE_NAME' has $ENDPOINTS endpoints"
        return 0
    else
        log_error "Service '$SERVICE_NAME' has no endpoints"
        return 1
    fi
}

# Test basic connectivity
test_connectivity() {
    log_info "Testing basic connectivity..."
    
    POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/name=ejabberd,app.kubernetes.io/instance=$RELEASE_NAME" --output json 2>/dev/null | jq -r '.items[0].metadata.name' 2>/dev/null)
    
    if [ -z "$POD_NAME" ] || [ "$POD_NAME" = "null" ]; then
        log_error "No pod found for connectivity testing"
        return 1
    fi
    
    # Test if we can exec into the pod
    if kubectl exec "$POD_NAME" -n "$NAMESPACE" -- echo "test" >/dev/null 2>&1; then
        log_success "Can execute commands in pod $POD_NAME"
    else
        log_error "Cannot execute commands in pod $POD_NAME"
        return 1
    fi
    
    # Test if ejabberd process is running
    if kubectl exec "$POD_NAME" -n "$NAMESPACE" -- pgrep -f ejabberd >/dev/null 2>&1; then
        log_success "ejabberd process is running in pod $POD_NAME"
    else
        log_error "ejabberd process is not running in pod $POD_NAME"
        return 1
    fi
    
    return 0
}

# Main function
main() {
    log_info "Starting health check for ejabberd deployment..."
    log_info "Namespace: $NAMESPACE"
    log_info "Release name: $RELEASE_NAME"
    echo
    
    # Check prerequisites
    if ! command -v kubectl >/dev/null 2>&1; then
        log_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        log_error "jq is not installed or not in PATH"
        exit 1
    fi
    
    # Run checks
    TESTS_PASSED=0
    TESTS_TOTAL=3
    
    check_pods && TESTS_PASSED=$((TESTS_PASSED + 1))
    check_service && TESTS_PASSED=$((TESTS_PASSED + 1))
    test_connectivity && TESTS_PASSED=$((TESTS_PASSED + 1))
    
    # Summary
    echo
    log_info "Health Check Summary:"
    log_info "Tests passed: $TESTS_PASSED/$TESTS_TOTAL"
    
    if [ "$TESTS_PASSED" -eq "$TESTS_TOTAL" ]; then
        log_success "Health check passed! ejabberd deployment is healthy."
        exit 0
    else
        log_error "Health check failed. Please check the deployment."
        exit 1
    fi
}

# Run main function
main "$@" 