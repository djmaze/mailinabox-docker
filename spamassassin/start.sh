#!/bin/bash

# Create directories for bayesian learning
mkdir -p $STORAGE_ROOT/mail/spamassassin
chown spampd:spampd $STORAGE_ROOT/mail/spamassassin

# Create empty bayes training data (if it doesn't exist).
sudo -u spampd /usr/bin/sa-learn --sync 2>/dev/null

# Initial training?
# sa-learn --ham storage/mail/mailboxes/*/*/cur/
# sa-learn --spam storage/mail/mailboxes/*/*/.Spam/cur/

syslog-stdout.py &
exec spampd --nodetach --user=spampd --group=spampd --host=0.0.0.0 --relayhost=dovecot --relayport=10026 --maxsize=500 --tagall --L
