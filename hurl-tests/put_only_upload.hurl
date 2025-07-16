# put_only_upload.hurl - Example of PUT request with body

# Test PUT request with body (using httpbin.org for demonstration)
PUT https://httpbin.org/put
Content-Type: text/plain
`This is a test file content.`
HTTP/2 200 