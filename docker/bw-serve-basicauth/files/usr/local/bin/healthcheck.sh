#!/bin/bash
# healthcheck.sh

# 1. Check if Nginx is responding
echo "Checking if Nginx is responding..."
curl  --silent --show-error --fail -u "$NGINX_USER:$NGINX_PASSWORD" http://localhost:80/status  -H "Content-Type: application/json" || exit 1

# 2. Check if Bitwarden is unlocked (using your existing logic)
echo "Checking if Bitwarden is unlocked..."
STATUS="$(curl --silent --show-error --fail -u "$NGINX_USER:$NGINX_PASSWORD" -X GET "http://localhost:80/status" -H "Content-Type: application/json" | jq --raw-output .data.template.status)"

if [ "$STATUS" == "unlocked" ]; then
  exit 0
else
  echo "Vault is locked or unreachable"
  exit 1
fi
