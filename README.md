# ejabberd Helm Chart

A Kubernetes Helm chart for deploying ejabberd XMPP server with comprehensive API testing.

## Quick Start (Automated)

**One-command setup and testing:**
```bash
./setup-and-test.sh
```

**One-command cleanup:**
```bash
./teardown.sh
```

## Manual Setup (Optional)

If you prefer manual control:

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