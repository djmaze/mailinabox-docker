#!/bin/bash

source $STORAGE_ROOT/doveadm/password.env

# Setting a `postmaster_address` is required or LMTP won't start. An alias
# will be created automatically by our management daemon.
$TOOLS_DIR/editconf.py /etc/dovecot/conf.d/15-lda.conf \
	postmaster_address=postmaster@$PRIMARY_HOSTNAME

# Configure doveadm password (for remote access)
$TOOLS_DIR/editconf.py /etc/dovecot/conf.d/99-remote-doveadm.conf \
  doveadm_password=$DOVEADM_PASSWORD

# Create an empty database if it doesn't yet exist.
if [ ! -f $DB_PATH ]; then
  echo Creating new user database: $DB_PATH;
  echo "CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, email TEXT NOT NULL UNIQUE, password TEXT NOT NULL, extra, privileges TEXT NOT NULL DEFAULT '');" | sqlite3 $DB_PATH;
  echo "CREATE TABLE aliases (id INTEGER PRIMARY KEY AUTOINCREMENT, source TEXT NOT NULL UNIQUE, destination TEXT NOT NULL);" | sqlite3 $DB_PATH;
fi

# PERMISSIONS

# Ensure mailbox files have a directory that exists and are owned by the mail user.
mkdir -p $STORAGE_ROOT/mail/mailboxes
chown mail.mail $STORAGE_ROOT/mail/mailboxes

# Same for the sieve scripts.
mkdir -p $STORAGE_ROOT/mail/sieve
chown mail.mail $STORAGE_ROOT/mail/sieve

exec dovecot -F -c /etc/dovecot/dovecot.conf
