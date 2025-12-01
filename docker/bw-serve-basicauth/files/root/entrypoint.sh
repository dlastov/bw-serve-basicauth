#!/bin/bash

on-fail() {
  declare lineno="$1"
  declare bash_command="$2"
  echo "Failed at ${lineno} ${bash_command}" >&2
}

# Starts "bw serve" in the background, login using the BW_CLIENTID and BW_CLIENTSECRET
bw-start-bg() {
  local bw_session
  echo "bw-start"
  if [ -v "BW_SERVER_URL" ]; then
    echo "set server to: ${BW_SERVER_URL}"
    bw config server "${BW_SERVER_URL}"
  fi
  if [ -v "BW_CLIENTID" ] && [ -v "BW_CLIENTSECRET" ]; then
    echo "login with clientid '${BW_CLIENTID}' with password from BW_CLIENTSECRET variable"
    bw login --apikey
  else
    echo "ERROR: BW_CLIENTID or BW_CLIENTSECRET variable not set" >&2
    exit 2
  fi
  if [ -v "BW_PASSWORD" ]; then
    echo "unlocking using BW_PASSWORD"
    bw_session="$(bw unlock --passwordenv BW_PASSWORD --raw)"
  else
    echo "no BW_PASSWORD set, unlock later using something like: curl -X POST -H 'Content-Type: application/json' --data '{\"password\":\"YOUR_PASSWORD\"}'" http://localhost:8087/unlock
  fi
  BW_SESSION="$bw_session" bw serve --hostname all &
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

echo "Start entrypoint"

environment-check

if [ "$#" -eq 0 ]; then
  services-start
  wait -n -p PID
  echo "finished process $PID"
else
  echo starting CMD: "${@}"
  "${@}"
fi

echo "Finished entrypoint"
