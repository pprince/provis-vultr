#!/bin/sh

# SSH keys
in-target mkdir -p /root/.ssh
cat "/srv/preseed/authorized_keys" > /target/root/.ssh/authorized_keys
in-target chmod 700 /root
in-target chmod 700 /root/.ssh
in-target chmod 600 /root/.ssh/authorized_keys

exit 0
