#!/bin/bash
set -e

source $TOOLS_DIR/functions.sh

hide_output pip3 install rtyaml "email_validator==0.1.0-rc4"

# Listen on all IPs
sed -i "s/app.run.*/app.run(host='0.0.0.0', port=10222)/" /usr/local/mailinabox/management/daemon.py

# Link the management server daemon into a well known location.
rm -f /usr/local/bin/bin/mailinabox-daemon
ln -s /usr/local/mailinabox/management/daemon.py /usr/local/bin/mailinabox-daemon

cat > /etc/mailinabox.conf << EOF;
STORAGE_USER=$STORAGE_USER
STORAGE_ROOT=$STORAGE_ROOT
PRIMARY_HOSTNAME=$PRIMARY_HOSTNAME
PUBLIC_IP=$PUBLIC_IP
PUBLIC_IPV6=$PUBLIC_IPV6
PRIVATE_IP=$PRIVATE_IP
PRIVATE_IPV6=$PRIVATE_IPV6
CSR_COUNTRY=$CSR_COUNTRY
EOF

# FIXME All below
## Create an init script to start the management daemon and keep it
## running after a reboot.
#rm -f /etc/init.d/mailinabox
#ln -s $(pwd)/conf/management-initscript /etc/init.d/mailinabox
#hide_output update-rc.d mailinabox defaults

## Perform a daily backup.
#cat > /etc/cron.daily/mailinabox-backup << EOF;
##!/bin/bash
## Mail-in-a-Box --- Do not edit / will be overwritten on update.
## Perform a backup.
#$(pwd)/management/backup.py
#EOF
#chmod +x /etc/cron.daily/mailinabox-backup

## Perform daily status checks. Compare each day to the previous
## for changes and mail the changes to the administrator.
#cat > /etc/cron.daily/mailinabox-statuschecks << EOF;
##!/bin/bash
## Mail-in-a-Box --- Do not edit / will be overwritten on update.
## Run status checks.
#$(pwd)/management/status_checks.py --show-changes --smtp
#EOF
#chmod +x /etc/cron.daily/mailinabox-statuschecks
