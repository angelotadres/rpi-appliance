#!/bin/bash -e
# In-chroot: enable the appliance services and lock the default account so NO default
# credential ships (access is via setup.txt at first boot).
USER_NAME="${FIRST_USER_NAME:-pi}"

systemctl enable appliance-first-boot.service
systemctl enable docker

# The app runs as the appliance user via compose-up's docker access.
usermod -aG docker "${USER_NAME}"

# No default password: lock the account; first-boot setup.txt provisions access.
passwd -l "${USER_NAME}" || true
