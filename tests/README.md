# ejabberd Test Suite (TDD Approach)

This comprehensive test suite validates all core chat functionality of your ejabberd Helm deployment using [Hurl](https://github.com/Orange-OpenSource/hurl) - a command-line tool for testing HTTP requests.

## 🎯 Test-Driven Development (TDD) Approach

We follow a **TDD methodology**:
1. **Tests Define Success Criteria** - All test scenarios must pass for deployment to be considered successful
2. **Comprehensive Coverage** - Tests cover all essential chat functionality 
3. **Automated Validation** - Run tests automatically after deployment
4. **Continuous Integration** - Integrate with CI/CD pipelines

## 📋 Test Coverage

Our test suite covers **10 comprehensive areas** of chat functionality:

### 1. **Health Check** (`01-health-check.hurl`)
- Server status and availability
- API endpoint accessibility  
- Basic connectivity validation

### 2. **JWT Authentication** (`02-jwt-authentication.hurl`) 
- JWT token generation and validation
- Admin and user token scopes
- Token-based API access
- OAuth2 flows

### 3. **User Management** (`03-user-management.hurl`)
- User registration and authentication
- Account verification
- Roster/contact management
- User lifecycle operations

### 4. **Presence & Status** (`04-presence-status.hurl`)
- All presence states (available, away, dnd, xa, unavailable)
- Status messages and priorities
- Multi-resource presence
- Typing indicators (composing, paused, active, inactive, gone)
- Session management

### 5. **Core Messaging** (`04-xmpp-messaging.hurl`)
- Direct messaging between users
- Rich content and HTML messages
- Message receipts and delivery confirmations
- Message correction and carbon copies
- Unicode and emoji support

### 6. **User Profiles** (`05-vcard-profiles.hurl`)
- Complete vCard information (name, email, phone, etc.)
- Avatar/photo management
- Profile fields and contact information
- Legacy vCard support

### 7. **Group Chat (MUC)** (`05-muc-groupchat.hurl`)
- Room creation and configuration
- User invitations and management
- Group messaging
- Room affiliations and permissions
- Room history and archives

### 8. **Message Archives** (`06-message-archive.hurl`)
- Message Archive Management (MAM)
- Message history retrieval
- Archive preferences and settings
- Date-based queries and filtering

### 9. **Offline Messages** (`07-offline-messages.hurl`)
- Offline message storage and delivery
- Message queuing and expiration
- Last activity tracking
- Offline message count and management

### 10. **Privacy & Blocking** (`08-privacy-blocking.hurl`)
- Privacy lists and blocking rules
- Contact blocking and roster management
- Private XML storage for app settings
- User preferences and bookmarks

### 11. **Advanced Features** (`09-push-advanced.hurl`)
- Push notifications (XEP-0357)
- File upload and sharing (XEP-0363)
- Stream management for reliability
- Message reactions and retraction
- Modern XMPP extensions (encryption readiness, etc.)

## 🚀 Running Tests

### Prerequisites

1. **Install Hurl**:
   ```bash
   # macOS
   brew install hurl
   
   # Ubuntu/Debian  
   apt install hurl
   
   # Or download from: https://github.com/Orange-OpenSource/hurl
   ```

2. **Configure Variables**:
   Edit `variables.env` to match your deployment:
   ```bash
   base_url=http://your-ejabberd-host:5280
   domain=your.domain.com
   admin_password=your-admin-password
   test_password=your-test-password
   ```

### Run All Tests

```bash
./run-tests.sh
```

### Run Specific Test

```bash
./run-tests.sh 01-health-check
./run-tests.sh jwt-authentication  
./run-tests.sh presence-status
```

### Test Options

```bash
./run-tests.sh --help              # Show usage
./run-tests.sh --list              # List available tests
./run-tests.sh --verbose           # Enable verbose output
```

## 📊 Test Results

Tests generate detailed logs and HTML reports:

- **Logs**: `tests/logs/*.log` - Detailed execution logs
- **HTML Reports**: `tests/logs/*.html` - Visual test reports
- **Console Output**: Colored pass/fail results with summaries

Example output:
```
[INFO] Starting ejabberd API tests with Hurl...
[INFO] Running test: 01-health-check.hurl
✅ PASSED: 01-health-check.hurl
[INFO] Running test: 02-jwt-authentication.hurl  
✅ PASSED: 02-jwt-authentication.hurl
...
🎉 All tests passed!
```

## 🔧 Customization

### Adding New Tests

1. Create new `.hurl` file in tests directory
2. Add to `TEST_FILES` array in `run-tests.sh`
3. Follow existing patterns for structure and assertions

### Test Structure

Each test file follows this pattern:
```hurl
# Test Description
# Brief explanation of what this test validates

# Test Step 1
POST {{base_url}}/api/endpoint
Content-Type: application/json
Authorization: Bearer {{access_token}}
{
  "param": "value"
}
HTTP 200
[Captures]
variable: jsonpath "$.field"
[Asserts]  
jsonpath "$.status" == "success"

# Test Step 2
GET {{base_url}}/api/other-endpoint
Authorization: Bearer {{access_token}}
HTTP 200
[Asserts]
jsonpath "$" isCollection
```

### Variables

Configure test variables in `variables.env`:
- **base_url**: ejabberd HTTP API endpoint
- **domain**: Your XMPP domain
- **admin_password**: Admin user password
- **test_password**: Test user password
- **access_token**: JWT token (captured during auth tests)

## 🎛️ CI/CD Integration

### GitHub Actions Example

```yaml
name: ejabberd Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Hurl
        run: |
          curl -LO https://github.com/Orange-OpenSource/hurl/releases/download/4.2.0/hurl_4.2.0_amd64.deb
          sudo dpkg -i hurl_4.2.0_amd64.deb
      - name: Deploy ejabberd
        run: |
          helm install ejabberd ./
          kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=ejabberd
      - name: Run Tests
        run: |
          cd tests
          ./run-tests.sh
```

### Kubernetes Job

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: ejabberd-tests
spec:
  template:
    spec:
      containers:
      - name: hurl-tests
        image: orangeopensource/hurl:latest
        command: ["/bin/sh", "-c"]
        args: ["cd /tests && ./run-tests.sh"]
        volumeMounts:
        - name: tests
          mountPath: /tests
      volumes:
      - name: tests
        configMap:
          name: ejabberd-tests
      restartPolicy: Never
```

## 🏗️ Architecture Benefits

### Why This Approach Works

1. **Clear Success Criteria**: Tests define exactly what "working" means
2. **Comprehensive Coverage**: All major chat features are validated
3. **Fast Feedback**: Immediate validation of deployments
4. **Documentation**: Tests serve as living documentation
5. **Regression Prevention**: Catch issues before they reach production
6. **Platform Agnostic**: Works with any ejabberd deployment

### TDD Benefits for Helm Charts

- **Confidence**: Deploy knowing all features work
- **Validation**: Automated verification of complex configurations  
- **Debugging**: Pinpoint exactly which features fail
- **Evolution**: Add new features with corresponding tests
- **Collaboration**: Shared understanding of expected behavior

## 🔍 Troubleshooting

### Common Issues

1. **Connection Refused**: Check if ejabberd is running and accessible
2. **Authentication Failed**: Verify admin credentials in `variables.env`
3. **Domain Issues**: Ensure domain configuration matches ejabberd setup
4. **Module Not Loaded**: Some tests require specific ejabberd modules

### Debugging Tips

```bash
# Run with verbose output
./run-tests.sh --verbose

# Check specific test logs
cat tests/logs/01-health-check.log

# Test connectivity manually
curl -i http://your-ejabberd:5280/api/status

# Validate ejabberd configuration
kubectl exec -it ejabberd-pod -- ejabberdctl status
```

## 📚 References

- [Hurl Documentation](https://hurl.dev/)
- [ejabberd API Reference](https://docs.ejabberd.im/developer/ejabberd-api/admin-api/)
- [XMPP Specifications](https://xmpp.org/rfcs/)
- [Test-Driven Development](https://en.wikipedia.org/wiki/Test-driven_development)

---

**Built with ❤️ for reliable ejabberd deployments** 