#!/bin/bash -e
# Install Docker Engine + compose v2 in the image. Debian's docker.io lacks the
# compose v2 plugin that compose-up uses, so use Docker's official installer.
export DEBIAN_FRONTEND=noninteractive
curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
sh /tmp/get-docker.sh
rm -f /tmp/get-docker.sh
# Belt-and-braces: ensure the compose plugin is present.
apt-get install -y --no-install-recommends docker-compose-plugin || true
