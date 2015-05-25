#!/bin/bash

mkdir -p $STORAGE_ROOT/mail/dkim

# Create a new DKIM key. This creates
# mail.private and mail.txt in $STORAGE_ROOT/mail/dkim. The former
# is the actual private key and the latter is the suggested DNS TXT
# entry which we'll want to include in our DNS setup.
if [ ! -f "$STORAGE_ROOT/mail/dkim/mail.private" ]; then
  # Should we specify -h rsa-sha256?
  opendkim-genkey -r -s mail -D $STORAGE_ROOT/mail/dkim
fi

# Ensure files are owned by the opendkim user and are private otherwise.
chown -R opendkim:opendkim $STORAGE_ROOT/mail/dkim
chmod go-rwx $STORAGE_ROOT/mail/dkim

# FIXME Is this really needed?
touch /etc/opendkim/{KeyTable,SigningTable}

exec opendkim -f -x /etc/opendkim.conf -u opendkim -l
