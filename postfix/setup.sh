#!/bin/sh
set -e

# ### Outgoing Mail

# Enable the 'submission' port 587 smtpd server and tweak its settings.
#
# * Do not add the OpenDMAC Authentication-Results header. That should only be added
#   on incoming mail. Omit the OpenDMARC milter by re-setting smtpd_milters to the
#   OpenDKIM milter only. See dkim.sh.
# * Even though we dont allow auth over non-TLS connections (smtpd_tls_auth_only below, and without auth the cli>
#   send outbound mail), don't allow non-TLS mail submission on this port anyway to prevent accidental misconfig>
# * Require the best ciphers for incoming connections per http://baldric.net/2013/12/07/tls-ciphers-in-postfix-a>
#   By putting this setting here we leave opportunistic TLS on incoming mail at default cipher settings (any cip>
# * Give it a different name in syslog to distinguish it from the port 25 smtpd server.
# * Add a new cleanup service specific to the submission service ('authclean')
#   that filters out privacy-sensitive headers on mail being sent out by
#   authenticated users.
$TOOLS_DIR/editconf.py /etc/postfix/master.cf -s -w \
  "submission=inet n       -       -       -       -       smtpd
    -o syslog_name=postfix/submission
    # FIXME Re-add DKIM
    #-o smtpd_milters=inet:127.0.0.1:8891
    -o smtpd_tls_security_level=encrypt
    -o smtpd_tls_ciphers=high -o smtpd_tls_exclude_ciphers=aNULL,DES,3DES,MD5,DES+MD5,RC4 -o smtpd_tls_protocols=!SSLv2,!SSLv3
    -o cleanup_service_name=authclean" \
  "authclean=unix  n       -       -       -       0       cleanup
    -o header_checks=pcre:/etc/postfix/outgoing_mail_header_filters"

# Enable TLS on these and all other connections (i.e. ports 25 *and* 587) and
# require TLS before a user is allowed to authenticate. This also makes
# opportunistic TLS available on *incoming* mail.
# Set stronger DH parameters, which via openssl tend to default to 1024 bits
# (see ssl.sh).
$TOOLS_DIR/editconf.py /etc/postfix/main.cf \
  smtpd_tls_security_level=may\
  smtpd_tls_auth_only=yes \
  smtpd_tls_cert_file=$STORAGE_ROOT/ssl/ssl_certificate.pem \
  smtpd_tls_key_file=$STORAGE_ROOT/ssl/ssl_private_key.pem \
  smtpd_tls_dh1024_param_file=$STORAGE_ROOT/ssl/dh2048.pem \
  smtpd_tls_ciphers=medium \
  smtpd_tls_exclude_ciphers=aNULL \
  smtpd_tls_received_header=yes

# Prevent non-authenticated users from sending mail that requires being
# relayed elsewhere. We don't want to be an "open relay". On outbound
# mail, require one of:
#
# * `permit_sasl_authenticated`: Authenticated users (i.e. on port 587).
# * `permit_mynetworks`: Mail that originates locally.
# * `reject_unauth_destination`: No one else. (Permits mail whose destination is local and rejects other mail.)
$TOOLS_DIR/editconf.py /etc/postfix/main.cf \
  smtpd_relay_restrictions=permit_sasl_authenticated,permit_mynetworks,reject_unauth_destination


# ### DANE

# When connecting to remote SMTP servers, prefer TLS and use DANE if available.
#
# Prefering ("opportunistic") TLS means Postfix will use TLS if the remote end
# offers it, otherwise it will transmit the message in the clear. Postfix will
# accept whatever SSL certificate the remote end provides. Opportunistic TLS
# protects against passive easvesdropping (but not man-in-the-middle attacks).
# DANE takes this a step further:
#
# Postfix queries DNS for the TLSA record on the destination MX host. If no TLSA records are found,
# then opportunistic TLS is used. Otherwise the server certificate must match the TLSA records
# or else the mail bounces. TLSA also requires DNSSEC on the MX host. Postfix doesn't do DNSSEC
# itself but assumes the system's nameserver does and reports DNSSEC status. Thus this also
# relies on our local bind9 server being present and `smtp_dns_support_level=dnssec`.
#
# The `smtp_tls_CAfile` is superflous, but it eliminates warnings in the logs about untrusted certs,
# which we don't care about seeing because Postfix is doing opportunistic TLS anyway. Better to encrypt,
# even if we don't know if it's to the right party, than to not encrypt at all. Instead we'll
# now see notices about trusted certs. The CA file is provided by the package `ca-certificates`.
$TOOLS_DIR/editconf.py /etc/postfix/main.cf \
	smtp_tls_security_level=dane \
	smtp_dns_support_level=dnssec \
	smtp_tls_CAfile=/etc/ssl/certs/ca-certificates.crt \
	smtp_tls_loglevel=2

# ### Incoming Mail

# Increase the message size limit from 10MB to 128MB.
# The same limit is specified in nginx.conf for mail submitted via webmail and Z-Push.
$TOOLS_DIR/editconf.py /etc/postfix/main.cf \
	message_size_limit=134217728

# ### Destination Validation

# Use a Sqlite3 database to check whether a destination email address exists,
# and to perform any email alias rewrites in Postfix.
$TOOLS_DIR/editconf.py /etc/postfix/main.cf \
  virtual_mailbox_domains=sqlite:/etc/postfix/virtual-mailbox-domains.cf \
  virtual_mailbox_maps=sqlite:/etc/postfix/virtual-mailbox-maps.cf \
  virtual_alias_maps=sqlite:/etc/postfix/virtual-alias-maps.cf \
  local_recipient_maps=\$virtual_mailbox_maps

# SQL statement to check if we handle mail for a domain, either for users or aliases.
cat > /etc/postfix/virtual-mailbox-domains.cf << EOF;
dbpath=$DB_PATH
query = SELECT 1 FROM users WHERE email LIKE '%%@%s' UNION SELECT 1 FROM aliases WHERE source LIKE '%%@%s'
EOF

# SQL statement to check if we handle mail for a user.
cat > /etc/postfix/virtual-mailbox-maps.cf << EOF;
dbpath=$DB_PATH
query = SELECT 1 FROM users WHERE email='%s'
EOF

# SQL statement to rewrite an email address if an alias is present.
# Aliases have precedence over users, but that's counter-intuitive for
# catch-all aliases ("@domain.com") which should *not* catch mail users.
# To fix this, not only query the aliases table but also the users
# table, i.e. turn users into aliases from themselves to themselves.
# If there is both an alias and a user for the same address either
# might be returned by the UNION, so the whole query is wrapped in
# another select that prioritizes the alias definition.
cat > /etc/postfix/virtual-alias-maps.cf << EOF;
dbpath=$DB_PATH
query = SELECT destination from (SELECT destination, 0 as priority FROM aliases WHERE source='%s' UNION SELECT email as destination, 1 as priority FROM users WHERE email='%s') ORDER BY priority LIMIT 1;
EOF
