#
# Check that the ejabberd service is running and responding to requests.
#
POST {{ejabberd_api_url}}/api/status
Content-Type: application/json

{}

HTTP 200
[Asserts]
body contains "started" 