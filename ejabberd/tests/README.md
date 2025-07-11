# ejabberd Helm Chart Tests

This directory contains test scripts to verify that your ejabberd Helm deployment is working correctly with secrets and other configurations.

## Test Scripts

### 1. `test-deployment.sh` - Comprehensive Test Suite
This is the main test script that performs comprehensive verification of your ejabberd deployment.

**Tests included:**
- **Test 1**: Helm release status verification
- **Test 2**: Pod readiness and running status
- **Test 3**: Service connectivity and endpoint verification
- **Test 4**: Secrets and configuration validation
- **Test 5**: Log analysis for errors

### 2. `health-check.sh` - Simple Health Check
A lightweight health check script for basic connectivity testing.

**Checks included:**
- Pod status verification
- Service endpoint validation
- Basic connectivity testing

### 3. `run-tests.sh` - Test Runner
A wrapper script that runs the comprehensive test suite with proper configuration.

## Usage

### Prerequisites

Make sure you have the following tools installed:
- `kubectl` - Kubernetes command-line tool
- `helm` - Helm package manager
- `jq` - JSON processor

### Running Tests

#### Option 1: Using the test runner (Recommended)
```bash
# Run with default settings
./tests/run-tests.sh

# Run with custom configuration
NAMESPACE=my-namespace RELEASE_NAME=my-ejabberd ./tests/run-tests.sh
```

#### Option 2: Running individual tests
```bash
# Run comprehensive test suite
./tests/test-deployment.sh

# Run simple health check
./tests/health-check.sh
```

### Configuration

You can configure the tests using environment variables:

- `NAMESPACE`: Kubernetes namespace (default: "default")
- `RELEASE_NAME`: Helm release name (default: "ejabberd")
- `TIMEOUT`: Timeout for pod readiness in seconds (default: 300)

### Examples

```bash
# Test deployment in custom namespace
NAMESPACE=ejabberd-prod RELEASE_NAME=ejabberd-prod ./tests/run-tests.sh

# Test with shorter timeout
TIMEOUT=120 ./tests/run-tests.sh

# Run health check only
./tests/health-check.sh
```

## Test Details

### Test 1: Helm Release Status
- Verifies that the Helm release exists
- Checks that the release status is "deployed"
- Validates release metadata

### Test 2: Pod Readiness
- Waits for all pods to be in "Running" state
- Verifies that all pods are ready (Ready condition is True)
- Respects the configured number of replicas
- Includes timeout handling

### Test 3: Service Connectivity
- Validates that the service exists
- Checks that the service has endpoints
- Tests internal connectivity to various ports:
  - HTTP API (port 5280)
  - HTTPS (port 5443)
  - XMPP c2s (port 5222)
  - XMPP s2s (port 5269)

### Test 4: Secrets and Configuration
- Validates TLS certificate secrets (if configured)
- Checks Erlang cookie secrets (if configured)
- Verifies secret existence and accessibility

### Test 5: Log Analysis
- Analyzes recent logs from all pods
- Searches for error patterns (error, fatal, panic)
- Reports error counts without failing the test

## Troubleshooting

### Common Issues

1. **"kubectl not found"**
   - Install kubectl and ensure it's in your PATH
   - Verify your kubeconfig is properly configured

2. **"helm not found"**
   - Install Helm and ensure it's in your PATH

3. **"jq not found"**
   - Install jq: `brew install jq` (macOS) or `apt-get install jq` (Ubuntu)

4. **"No pods found"**
   - Verify the release name is correct
   - Check that the deployment exists in the specified namespace

5. **"Service has no endpoints"**
   - Check if pods are running and ready
   - Verify service selector matches pod labels

### Debug Mode

To get more detailed output, you can modify the scripts to include debug information:

```bash
# Add debug output to test scripts
set -x  # Add this line at the beginning of the script
```

## Integration with CI/CD

These tests can be easily integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions step
- name: Test ejabberd deployment
  run: |
    chmod +x ./ejabberd/tests/run-tests.sh
    ./ejabberd/tests/run-tests.sh
  env:
    NAMESPACE: ${{ env.NAMESPACE }}
    RELEASE_NAME: ${{ env.RELEASE_NAME }}
```

## Contributing

When adding new tests:

1. Follow the existing pattern with colored output
2. Include proper error handling
3. Add timeout mechanisms for long-running operations
4. Document new environment variables
5. Update this README with new test descriptions 