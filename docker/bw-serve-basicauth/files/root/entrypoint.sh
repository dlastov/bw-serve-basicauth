#!/bin/bash

on-fail() {
  declare lineno="$1"
  declare bash_command="$2"
  echo "Failed at ${lineno} ${bash_command}" >&2
}

cleanup() {
  echo -e "\nShutting down..."

  # Terminate background processes
  PIDS=$(jobs -p)
  if [ -n "$PIDS" ]; then
    echo "Stopping background services (PIDs: $PIDS)..."
    kill $PIDS 2>/dev/null || true
    wait $PIDS 2>/dev/null || true
  fi

  # Logout from Bitwarden to ensure a clean state for next start
  # Check if we are logged in
  if bw status | jq -e '.status != "unauthenticated"' >/dev/null 2>&1; then
    echo "Logging out from Bitwarden..."
    bw logout || true
  fi

  echo "Shutdown complete."
  exit 0
}

# Starts "bw serve" in the background, login using the BW_CLIENTID and BW_CLIENTSECRET
bw-start-bg() {
  echo "bw-start"

  # logout if there was not a clean shutdown
  if bw status | jq -e '.status != "unauthenticated"' >/dev/null 2>&1; then
    echo "Logging out from Bitwarden..."
    bw logout || true
  fi

  if [ -v "BW_SERVER_URL" ]; then
    echo "set server to: ${BW_SERVER_URL}"
    # Following command might produce the error below, if it was not cleanly shutdown:
    #   Logout required before server config update.
    bw config server "${BW_SERVER_URL}" || true
  fi

  # Check current status to avoid redundant login errors
  local status
  status=$(bw status | jq -r .status 2>/dev/null || echo "unauthenticated")
  echo "Current Bitwarden status: $status"

  if [ "$status" == "unauthenticated" ]; then
    if [ -v "BW_CLIENTID" ] && [ -v "BW_CLIENTSECRET" ]; then
      echo "login with clientid '${BW_CLIENTID}'"
      bw login --apikey
      echo -e "\n"
    else
      echo "ERROR: BW_CLIENTID or BW_CLIENTSECRET variable not set" >&2
      return 2
    fi
  fi

  if [ -v "BW_PASSWORD" ]; then
    echo "unlocking using BW_PASSWORD"
    BW_SESSION="$(bw unlock --passwordenv BW_PASSWORD --raw)"
    if [ $? -eq 0 ] && [ -n "$BW_SESSION" ]; then
      echo "unlocked"
      export BW_SESSION
    else
      echo "unlock failed"
      unset BW_SESSION
    fi
  else
    echo "no BW_PASSWORD set, unlock later using: curl -X POST -H 'Content-Type: application/json' --data '{\"password\":\"YOUR_PASSWORD\"}' http://localhost:80/unlock"
  fi
  bw serve --hostname all &
  echo "started 'bw serve', PID=$!"
}

environment-check() {
  echo "BW_SERVER_URL=$BW_SERVER_URL  # Server to connect to."
  echo "BW_CLIENTID=$BW_CLIENTID  # Vault clientid to login as."
  if [ -v BW_CLIENTSECRET ]; then
    echo "BW_CLIENTSECRET=XXXXXXXXXXXX  # client_secret required to login is set."
  fi
  if [ -v BW_PASSWORD ]; then
    echo "BW_PASSWORD=XXXXXXXXXXXX  # master password will automatically unlock the vault."
  fi
  if [ -v NGINX_USER ]; then
    echo "NGINX_USER=$NGINX_USER  # user to be requested for basic auth."
  else
    echo "NGINX_USER not specified. Using BW_CLIENTID by default."
  fi
  if [ -v NGINX_PASSWORD ]; then
    echo "NGINX_PASSWORD=XXXXXXXXXXXX  # password to be requested for basic auth."
  else
    echo "NGINX_PASSWORD not specified. Using BW_CLIENTSECRET by default."
  fi
}

# Starts nginx in the background, accepting connections only if Bearer token
# corresponds to passed token.
nginx-start-bg() {
  echo "nginx-start"
  if ! [ -v "NGINX_USER" ]; then
    NGINX_USER="$BW_CLIENTID"
  fi
  if ! [ -v "NGINX_PASSWORD" ]; then
    NGINX_PASSWORD="$BW_CLIENTSECRET"
  fi
  echo "$NGINX_PASSWORD" | htpasswd -ci /etc/nginx/htpasswd "$NGINX_USER"
  /usr/sbin/nginx -g "daemon off;" &
  echo "started nginx, PID=$!"
}

services-start() {
  bw-start-bg
  nginx-start-bg
}

set -eu  # Fail if something is wrong
trap 'on-fail "${LINENO}" "${BASH_COMMAND}"' ERR
trap cleanup SIGTERM SIGINT

echo -e "\n\nStart entrypoint"

environment-check

if [ "$#" -eq 0 ]; then
  services-start
  wait -n -p PID
  echo "finished process $PID"
  cleanup
else
  echo starting CMD: "${@}"
  exec "${@}"
fi

echo "Finished entrypoint"
