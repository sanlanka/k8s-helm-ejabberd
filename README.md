# ejabberd Helm Chart

A Kubernetes Helm chart for deploying ejabberd XMPP server with API testing.

## Quick Start

1. **Deploy ejabberd**:
   ```bash
   helm install my-ejabberd ./ejabberd
   ```

2. **Set up port forwarding**:
   ```bash
   kubectl port-forward service/my-ejabberd 5280:5280 &
   ```

3. **Run tests**:
   ```bash
   hurl --variables-file tests/vars.env --test --jobs 1 tests/*.hurl
   ```

## Test Suite

The tests verify:
- Server status
- User registration
- User existence check
- User unregistration  
- User deletion verification

**Note**: Use `--jobs 1` to run tests sequentially (required for test dependencies). 