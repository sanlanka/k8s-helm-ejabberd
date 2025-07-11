#!/bin/bash

# Test script for ejabberd Helm deployment
# This script verifies that the deployment is working correctly with secrets

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE=${NAMESPACE:-"default"}
RELEASE_NAME=${RELEASE_NAME:-"ejabberd"}
TIMEOUT=${TIMEOUT:-300} # 5 minutes timeout

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

# Test 1: Check if Helm release is deployed
test_helm_release() {
    log_info "Test 1: Checking Helm release status..."
    
    if ! helm list -n "$NAMESPACE" | grep -q "$RELEASE_NAME"; then
        log_error "Helm release '$RELEASE_NAME' not found in namespace '$NAMESPACE'"
        return 1
    fi
    
    RELEASE_STATUS=$(helm status "$RELEASE_NAME" -n "$NAMESPACE" --output json 2>/dev/null | jq -r '.info.status' 2>/dev/null || echo "unknown")
    
    if [ "$RELEASE_STATUS" = "deployed" ]; then
        log_success "Helm release '$RELEASE_NAME' is deployed successfully"
        return 0
    else
        log_error "Helm release '$RELEASE_NAME' is not properly deployed. Status: $RELEASE_STATUS"
        return 1
    fi
}

# Test 2: Check if pods are running
test_pods_running() {
    log_info "Test 2: Checking if pods are running..."
    
    # Get the expected number of replicas
    EXPECTED_REPLICAS=$(helm get values "$RELEASE_NAME" -n "$NAMESPACE" --output json 2>/dev/null | jq -r '.statefulSet.replicas // 3' 2>/dev/null || echo "3")
    
    # Wait for pods to be ready
    log_info "Waiting for $EXPECTED_REPLICAS pods to be ready (timeout: ${TIMEOUT}s)..."
    
    READY_PODS=0
    ELAPSED=0
    
    while [ $ELAPSED -lt $TIMEOUT ]; do
        READY_PODS=$(kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/name=ejabberd,app.kubernetes.io/instance=$RELEASE_NAME" --output json 2>/dev/null | jq -r '.items[] | select(.status.phase == "Running" and (.status.conditions[] | select(.type == "Ready").status == "True")) | .metadata.name' 2>/dev/null | wc -l)
        
        if [ "$READY_PODS" -eq "$EXPECTED_REPLICAS" ]; then
            log_success "All $EXPECTED_REPLICAS pods are running and ready"
            return 0
        fi
        
        log_info "Ready pods: $READY_PODS/$EXPECTED_REPLICAS"
        sleep 10
        ELAPSED=$((ELAPSED + 10))
    done
    
    log_error "Timeout waiting for pods to be ready. Only $READY_PODS/$EXPECTED_REPLICAS pods are ready"
    return 1
}

# Test 3: Check service connectivity
test_service_connectivity() {
    log_info "Test 3: Checking service connectivity..."
    
    # Get service details
    SERVICE_NAME=$(kubectl get svc -n "$NAMESPACE" -l "app.kubernetes.io/name=ejabberd,app.kubernetes.io/instance=$RELEASE_NAME" --output json 2>/dev/null | jq -r '.items[0].metadata.name' 2>/dev/null)
    
    if [ -z "$SERVICE_NAME" ] || [ "$SERVICE_NAME" = "null" ]; then
        log_error "Service not found for release '$RELEASE_NAME'"
        return 1
    fi
    
    log_info "Found service: $SERVICE_NAME"
    
    # Check if service has endpoints
    ENDPOINTS=$(kubectl get endpoints "$SERVICE_NAME" -n "$NAMESPACE" --output json 2>/dev/null | jq -r '.subsets[0].addresses | length' 2>/dev/null || echo "0")
    
    if [ "$ENDPOINTS" -gt 0 ]; then
        log_success "Service '$SERVICE_NAME' has $ENDPOINTS endpoints"
    else
        log_error "Service '$SERVICE_NAME' has no endpoints"
        return 1
    fi
    
    # Test basic connectivity (if we can port-forward)
    log_info "Testing basic connectivity..."
    
    # Get the first pod name for port-forwarding
    POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/name=ejabberd,app.kubernetes.io/instance=$RELEASE_NAME" --output json 2>/dev/null | jq -r '.items[0].metadata.name' 2>/dev/null)
    
    if [ -n "$POD_NAME" ] && [ "$POD_NAME" != "null" ]; then
        log_info "Testing connectivity to pod: $POD_NAME"
        
        # Test HTTP API endpoint (port 5280)
        if kubectl exec "$POD_NAME" -n "$NAMESPACE" -- curl -s -f http://localhost:5280/api/status >/dev/null 2>&1; then
            log_success "HTTP API endpoint (port 5280) is accessible"
        else
            log_warning "HTTP API endpoint (port 5280) is not accessible"
        fi
        
        # Test HTTPS endpoint (port 5443)
        if kubectl exec "$POD_NAME" -n "$NAMESPACE" -- curl -s -f -k https://localhost:5443 >/dev/null 2>&1; then
            log_success "HTTPS endpoint (port 5443) is accessible"
        else
            log_warning "HTTPS endpoint (port 5443) is not accessible"
        fi
        
        # Test XMPP c2s port (5222)
        if kubectl exec "$POD_NAME" -n "$NAMESPACE" -- nc -z localhost 5222 2>/dev/null; then
            log_success "XMPP c2s port (5222) is listening"
        else
            log_warning "XMPP c2s port (5222) is not listening"
        fi
        
        # Test XMPP s2s port (5269)
        if kubectl exec "$POD_NAME" -n "$NAMESPACE" -- nc -z localhost 5269 2>/dev/null; then
            log_success "XMPP s2s port (5269) is listening"
        else
            log_warning "XMPP s2s port (5269) is not listening"
        fi
        
    else
        log_warning "Could not find pod for connectivity testing"
    fi
    
    return 0
}

# Test 4: Check secrets and configuration
test_secrets_config() {
    log_info "Test 4: Checking secrets and configuration..."
    
    # Check if TLS certificates are configured
    TLS_SECRETS=$(helm get values "$RELEASE_NAME" -n "$NAMESPACE" --output json 2>/dev/null | jq -r '.certFiles.secretName[]?' 2>/dev/null || echo "")
    
    if [ -n "$TLS_SECRETS" ]; then
        log_info "TLS certificates configured: $TLS_SECRETS"
        
        for secret in $TLS_SECRETS; do
            if kubectl get secret "$secret" -n "$NAMESPACE" >/dev/null 2>&1; then
                log_success "TLS secret '$secret' exists"
            else
                log_error "TLS secret '$secret' not found"
                return 1
            fi
        done
    else
        log_warning "No TLS certificates configured"
    fi
    
    # Check Erlang cookie configuration
    ERLANG_COOKIE_SECRET=$(helm get values "$RELEASE_NAME" -n "$NAMESPACE" --output json 2>/dev/null | jq -r '.erlangCookie.secretName // empty' 2>/dev/null)
    
    if [ -n "$ERLANG_COOKIE_SECRET" ]; then
        if kubectl get secret "$ERLANG_COOKIE_SECRET" -n "$NAMESPACE" >/dev/null 2>&1; then
            log_success "Erlang cookie secret '$ERLANG_COOKIE_SECRET' exists"
        else
            log_error "Erlang cookie secret '$ERLANG_COOKIE_SECRET' not found"
            return 1
        fi
    else
        log_info "Using default Erlang cookie value"
    fi
    
    return 0
}

# Test 5: Check logs for errors
test_logs() {
    log_info "Test 5: Checking pod logs for errors..."
    
    PODS=$(kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/name=ejabberd,app.kubernetes.io/instance=$RELEASE_NAME" --output json 2>/dev/null | jq -r '.items[].metadata.name' 2>/dev/null)
    
    ERROR_COUNT=0
    
    for pod in $PODS; do
        if [ -n "$pod" ] && [ "$pod" != "null" ]; then
            log_info "Checking logs for pod: $pod"
            
            # Check for error patterns in logs
            ERROR_LINES=$(kubectl logs "$pod" -n "$NAMESPACE" --tail=50 2>/dev/null | grep -i "error\|fatal\|panic" | wc -l)
            
            if [ "$ERROR_LINES" -gt 0 ]; then
                log_warning "Found $ERROR_LINES error lines in pod $pod"
                ERROR_COUNT=$((ERROR_COUNT + ERROR_LINES))
            else
                log_success "No errors found in pod $pod logs"
            fi
        fi
    done
    
    if [ "$ERROR_COUNT" -eq 0 ]; then
        log_success "No errors found in any pod logs"
        return 0
    else
        log_warning "Found $ERROR_COUNT error lines across all pods"
        return 0  # Don't fail the test for warnings
    fi
}

# Main test execution
main() {
    log_info "Starting ejabberd deployment tests..."
    log_info "Namespace: $NAMESPACE"
    log_info "Release name: $RELEASE_NAME"
    log_info "Timeout: ${TIMEOUT}s"
    
    # Check prerequisites
    if ! command -v kubectl >/dev/null 2>&1; then
        log_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v helm >/dev/null 2>&1; then
        log_error "helm is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        log_error "jq is not installed or not in PATH"
        exit 1
    fi
    
    # Run tests
    TESTS_PASSED=0
    TESTS_TOTAL=5
    
    test_helm_release && TESTS_PASSED=$((TESTS_PASSED + 1))
    test_pods_running && TESTS_PASSED=$((TESTS_PASSED + 1))
    test_service_connectivity && TESTS_PASSED=$((TESTS_PASSED + 1))
    test_secrets_config && TESTS_PASSED=$((TESTS_PASSED + 1))
    test_logs && TESTS_PASSED=$((TESTS_PASSED + 1))
    
    # Summary
    echo
    log_info "Test Summary:"
    log_info "Tests passed: $TESTS_PASSED/$TESTS_TOTAL"
    
    if [ "$TESTS_PASSED" -eq "$TESTS_TOTAL" ]; then
        log_success "All tests passed! ejabberd deployment is working correctly."
        exit 0
    else
        log_error "Some tests failed. Please check the deployment."
        exit 1
    fi
}

# Run main function
main "$@" 