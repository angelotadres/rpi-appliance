# Test harness: an "appliance" in setup-password mode — password auth on, a known
# setup password, NOPASSWD sudo, and the real appliance lockdown script + sudoers.
# Build context = repo root.
FROM debian:12-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends openssh-server sudo passwd \
 && rm -rf /var/lib/apt/lists/* \
 && useradd -m -s /bin/bash pi \
 && echo 'pi:setup-pass-123' | chpasswd \
 && mkdir -p /run/sshd /opt/appliance/bin /etc/ssh/sshd_config.d \
 && ssh-keygen -A

COPY appliance/rootfs/opt/appliance/bin/lockdown /opt/appliance/bin/lockdown
COPY appliance/rootfs/etc/ssh/sshd_config.d/10-appliance.conf /etc/ssh/sshd_config.d/10-appliance.conf
COPY appliance/rootfs/etc/sudoers.d/010-appliance /etc/sudoers.d/010-appliance
RUN chmod +x /opt/appliance/bin/lockdown \
 && chmod 440 /etc/sudoers.d/010-appliance \
 && visudo -cf /etc/sudoers.d/010-appliance \
 # setup-password window: 00- sorts ahead of the key-only baseline (10-).
 && printf 'PasswordAuthentication yes\n' > /etc/ssh/sshd_config.d/00-appliance-setup.conf

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D", "-e"]
