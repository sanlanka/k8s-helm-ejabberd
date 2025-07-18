# minimal_upload.hurl

# 1. Request an upload slot
GET http://localhost:5280/upload?filename=test-image.jpg&size=20&content-type=image/jpeg

HTTP/1.1 *

# 2. Upload the file to the returned put_url (simulate with text)
# NOTE: Hurl does not support dynamic URL from previous step, so we hardcode the URL for now
PUT http://localhost:5280/upload/test-image.jpg
Content-Type: image/jpeg
`This is a test image file.`
HTTP/1.1 * 