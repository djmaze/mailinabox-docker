#!/bin/bash

# Configure doveadm password (for remote access)
cat >> /etc/dovecot/conf.d/99-remote-doveadm.conf << EOF;
doveadm_password = $DOVEADM_PASSWORD
EOF

# FIXME Put only needed in variables in mailinabox.conf. Even better, get rid of that extra file!
env >/etc/mailinabox.conf

exec /usr/local/bin/mailinabox-daemon
