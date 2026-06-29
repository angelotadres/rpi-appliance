# Test harness only: a real sshd to exercise the appliance's secure-access scripts
# off-Pi. Build context is appliance/ so it can copy rootfs/ and opt/.
FROM debian:12-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends openssh-server passwd \
 && rm -rf /var/lib/apt/lists/* \
 && useradd -m -s /bin/bash pi \
 && mkdir -p /run/sshd /etc/ssh/sshd_config.d \
 && ssh-keygen -A

COPY rootfs/etc/ssh/sshd_config.d/10-appliance.conf /etc/ssh/sshd_config.d/10-appliance.conf
COPY rootfs/opt/appliance/bin/ /opt/appliance/bin/
RUN chmod +x /opt/appliance/bin/*

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D", "-e"]
