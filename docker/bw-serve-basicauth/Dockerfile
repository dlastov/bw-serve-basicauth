FROM ubuntu:24.04
COPY files .
ARG BW_SERVER_URL
ARG BW_CLI_RELEASE_URL
ENV BW_SERVER_URL=${BW_SERVER_URL:-https://vault.bitwarden.com}
ENV BW_CLI_RELEASE_URL=${BW_CLI_RELEASE_URL:-https://github.com/bitwarden/clients/releases/download/cli-v2025.12.1/bw-linux-2025.12.1.zip}
RUN ["/bin/bash", "/root/setup.sh"]
EXPOSE 80
ENTRYPOINT ["/root/entrypoint.sh"]
