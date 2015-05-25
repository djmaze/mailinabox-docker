#!/bin/bash

# Set some basic settings...
#
# * Have postfix listen on all network interfaces.
# * Set our name (the Debian default seems to be "localhost" but make it our hostname).
# * Set the name of the local machine to localhost, which means xxx@localhost is delivered locally, although we >
# * Set the SMTP banner (which must have the hostname first, then anything).
$TOOLS_DIR/editconf.py /etc/postfix/main.cf \
  inet_interfaces=all \
  myhostname=$PRIMARY_HOSTNAME\
  smtpd_banner="\$myhostname ESMTP Hi, I'm a Mail-in-a-Box (Ubuntu/Postfix; see https://mailinabox.email/)" \
  mydestination=localhost

# Use SASL auth service provided by dovecot
$TOOLS_DIR/editconf.py /etc/postfix/main.cf \
  smtpd_sasl_type=dovecot \
  smtpd_sasl_path=inet:$DOVECOT_1_PORT_12345_TCP_ADDR:12345 \
  smtpd_sasl_auth_enable=yes

# Pass any incoming mail over to a local delivery agent. Spamassassin
# will act as the LDA agent at first. It is listening on port 10025
# with LMTP. Spamassassin will pass the mail over to Dovecot after.
#
# In a basic setup we would pass mail directly to Dovecot by setting
# virtual_transport to `lmtp:unix:private/dovecot-lmtp`.
#
$TOOLS_DIR/editconf.py /etc/postfix/main.cf virtual_transport=lmtp:[$SPAMASSASSIN_PORT_10025_TCP_ADDR]:10025

# Who can send mail to us? Some basic filters.
#
# * `reject_non_fqdn_sender`: Reject not-nice-looking return paths.
# * `reject_unknown_sender_domain`: Reject return paths with invalid domains.
# * `reject_rhsbl_sender`: Reject return paths that use blacklisted domains.
# * `permit_sasl_authenticated`: Authenticated users (i.e. on port 587) can skip further checks.
# * `permit_mynetworks`: Mail that originates locally can skip further checks.
# * `reject_rbl_client`: Reject connections from IP addresses blacklisted in zen.spamhaus.org
# * `reject_unlisted_recipient`: Although Postfix will reject mail to unknown recipients, it's nicer to reject such mail ahead of greylisting rather than after.
# * `check_policy_service`: Apply greylisting using postgrey.
#
# Notes: #NODOC
# permit_dnswl_client can pass through mail from whitelisted IP addresses, which would be good to put before greylisting #NODOC
# so these IPs get mail delivered quickly. But when an IP is not listed in the permit_dnswl_client list (i.e. it is not #NODOC
# whitelisted) then postfix does a DEFER_IF_REJECT, which results in all "unknown user" sorts of messages turning into #NODOC
# "450 4.7.1 Client host rejected: Service unavailable". This is a retry code, so the mail doesn't properly bounce. #NODOC
$TOOLS_DIR/editconf.py /etc/postfix/main.cf \
	smtpd_sender_restrictions="reject_non_fqdn_sender,reject_unknown_sender_domain,reject_rhsbl_sender dbl.spamhaus.org" \
	smtpd_recipient_restrictions=permit_sasl_authenticated,permit_mynetworks,"reject_rbl_client zen.spamhaus.org",reject_unlisted_recipient,"check_policy_service inet:$POSTGREY_1_PORT_10023_TCP_ADDR:10023"

# Add OpenDKIM and OpenDMARC as milters to postfix, which is how OpenDKIM
# intercepts outgoing mail to perform the signing (by adding a mail header)
# and how they both intercept incoming mail to add Authentication-Results
# headers. The order possibly/probably matters: OpenDMARC relies on the
# OpenDKIM Authentication-Results header already being present.
#
# Be careful. If we add other milters later, this needs to be concatenated
# on the smtpd_milters line.
#
# The OpenDMARC milter is skipped in the SMTP submission listener by
# configuring smtpd_milters there to only list the OpenDKIM milter
# (see mail-postfix.sh).
$TOOLS_DIR/editconf.py /etc/postfix/main.cf \
  "smtpd_milters=inet:$OPENDKIM_1_PORT_8891_TCP_ADDR:8891 inet:$OPENDMARC_1_PORT_8893_TCP_ADDR:8893"\
  non_smtpd_milters=\$smtpd_milters \
  milter_default_action=accept

exec /usr/lib/postfix/master -d
