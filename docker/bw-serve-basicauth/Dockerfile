FROM ubuntu:24.04
COPY files .
ARG BW_SERVER_URL
ARG BW_CLI_RELEASE_URL
ENV BW_SERVER_URL=${BW_SERVER_URL:-https://vault.bitwarden.com}
ENV BW_CLI_RELEASE_URL=${BW_CLI_RELEASE_URL:-https://github.com/bitwarden/clients/releases/download/cli-v2025.12.1/bw-linux-2025.12.1.zip}
RUN ["/bin/bash", "/root/setup.sh"]
EXPOSE 80
ENTRYPOINT ["/root/entrypoint.sh"]
# HEALTHCHECK configuration
# interval: how often to run
# timeout: how long to wait for the response
# start-period: give the container 15s to boot up before failing
# retries: fail 3 times before marking "Unhealthy"
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD ["/usr/local/bin/healthcheck.sh"]
