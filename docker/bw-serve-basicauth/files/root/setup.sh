#!/bin/bash

on_fail() {
  declare lineno="$1"
  declare bash_command="$2"
  echo "Failed at ${lineno} ${bash_command}" >&2
}

install_packages() {
  echo "Installing packages"
  apt-get -y update
  # apache2-utils: contains htpasswd
  # curl: to download bw cli
  # jq: for convenience
  # nginx: used as the reverse proxy
  # vim: for convenience
  apt-get -y install apache2-utils curl jq nginx vim
  # /bin/bw: server implementing the Bitwarden Vault API
  curl -Lsf "$BW_CLI_RELEASE_URL" | zcat > /bin/bw
  chmod +x /bin/bw
}

config_bw() {
  echo "Configuring bw"
  if [ -v "BW_SERVER_URL" ]; then
    echo "- set server as ${BW_SERVER_URL}"
    bw config server "${BW_SERVER_URL}"
  fi
}

config_nginx() {
  echo "Configuring nginx"
  rm /etc/nginx/sites-enabled/default
  ln -s /etc/nginx/sites-available/bw_proxy /etc/nginx/sites-enabled/bw_proxy
}

set -eu  # Fail if something is wrong
trap 'on_fail "${LINENO}" "${BASH_COMMAND}"' ERR

echo "Start setup"
echo "BW_SERVER_URL=$BW_SERVER_URL  # Default server to connect to"
echo "BW_CLI_RELEASE_URL=$BW_CLI_RELEASE_URL  # URL from which to download the BW CLI"

install_packages
# it seems more error prone to config bw only in entrypoint.sh
#config_bw
config_nginx

echo "Finished setup"
