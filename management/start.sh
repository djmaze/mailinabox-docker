#!/bin/bash

# Configure doveadm password (for remote access)
cat >> /etc/dovecot/conf.d/99-remote-doveadm.conf << EOF;
doveadm_password = $DOVEADM_PASSWORD
EOF

exec /usr/local/bin/mailinabox-daemon
