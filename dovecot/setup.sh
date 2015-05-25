#!/bin/bash
set -e

# Set basic daemon options.

# The `default_process_limit` is 100, which constrains the total number
# of active IMAP connections (at, say, 5 open connections per user that
# would be 20 users). Set it to 250 times the number of cores this
# machine has, so on a two-core machine that's 500 processes/100 users).
$TOOLS_DIR/editconf.py /etc/dovecot/conf.d/10-master.conf \
	default_process_limit=$(echo "`nproc` * 250" | bc)

# The inotify `max_user_instances` default is 128, which constrains
# the total number of watched (IMAP IDLE push) folders by open connections.
# See http://www.dovecot.org/pipermail/dovecot/2013-March/088834.html.
# A reboot is required for this to take effect (which we don't do as
# as a part of setup). Test with `cat /proc/sys/fs/inotify/max_user_instances`.
# FIXME: Find a solution for this on Docker. (Also see https://github.com/docker/docker/issues/1044)
$TOOLS_DIR/editconf.py /etc/sysctl.conf \
	fs.inotify.max_user_instances=1024

# Set the location where we'll store user mailboxes. '%d' is the domain name and '%n' is the
# username part of the user's email address. We'll ensure that no bad domains or email addresses
# are created within the management daemon.
$TOOLS_DIR/editconf.py /etc/dovecot/conf.d/10-mail.conf \
	mail_location=maildir:$STORAGE_ROOT/mail/mailboxes/%d/%n \
	mail_privileged_group=mail \
	first_valid_uid=0

# ### IMAP/POP

# Require that passwords are sent over SSL only, and allow the usual IMAP authentication mechanisms.
# The LOGIN mechanism is supposedly for Microsoft products like Outlook to do SMTP login (I guess
# since we're using Dovecot to handle SMTP authentication?).
$TOOLS_DIR/editconf.py /etc/dovecot/conf.d/10-auth.conf \
	disable_plaintext_auth=yes \
	"auth_mechanisms=plain login"

# Enable SSL, specify the location of the SSL certificate and private key files.
# Disable obsolete SSL protocols and allow only good ciphers per http://baldric.net/2013/12/07/tls-ciphers-in-postfix-and-dovecot/.
$TOOLS_DIR/editconf.py /etc/dovecot/conf.d/10-ssl.conf \
	ssl=required \
	"ssl_cert=<$STORAGE_ROOT/ssl/ssl_certificate.pem" \
	"ssl_key=<$STORAGE_ROOT/ssl/ssl_private_key.pem" \
	"ssl_protocols=!SSLv3 !SSLv2" \
	"ssl_cipher_list=TLSv1+HIGH !SSLv2 !RC4 !aNULL !eNULL !3DES @STRENGTH"

# Disable in-the-clear IMAP/POP because there is no reason for a user to transmit
# login credentials outside of an encrypted connection. Only the over-TLS versions
# are made available (IMAPS on port 993; POP3S on port 995).
sed -i "s/#port = 143/port = 0/" /etc/dovecot/conf.d/10-master.conf
sed -i "s/#port = 110/port = 0/" /etc/dovecot/conf.d/10-master.conf

# Make IMAP IDLE slightly more efficient. By default, Dovecot says "still here"
# every two minutes. With K-9 mail, the bandwidth and battery usage due to
# this are minimal. But for good measure, let's go to 4 minutes to halve the
# bandwidth and number of times the device's networking might be woken up.
# The risk is that if the connection is silent for too long it might be reset
# by a peer. See #129 and http://razor.occams.info/blog/2014/08/09/how-bad-is-imap-idle/.
$TOOLS_DIR/editconf.py /etc/dovecot/conf.d/20-imap.conf \
	imap_idle_notify_interval="4 mins"

# Set POP3 UIDL
# UIDLs are used by POP3 clients to keep track of what messages they've downloaded. 
# For new POP3 servers, the easiest way to set up UIDLs is to use IMAP's UIDVALIDITY
# and UID values, the default in Dovecot.
$TOOLS_DIR/editconf.py /etc/dovecot/conf.d/20-pop3.conf \
	pop3_uidl_format="%08Xu%08Xv"

# ### LDA (LMTP)

# Enable Dovecot's LDA service with the LMTP protocol. It will listen
# on port 10026, and Spamassassin will be configured to pass mail there.
#
# The disabled unix socket listener is normally how Postfix and Dovecot
# would communicate (see the Postfix setup script for the corresponding
# setting also commented out).
#
# Also increase the number of allowed IMAP connections per mailbox because
# we all have so many devices lately.
cat > /etc/dovecot/conf.d/99-local.conf << EOF;
service lmtp {
  #unix_listener /var/spool/postfix/private/dovecot-lmtp {
  #  user = postfix
  #  group = postfix
  #}
  inet_listener lmtp {
    address = 0.0.0.0
    port = 10026
  }
}

protocol imap {
  mail_max_userip_connections = 20
}
EOF

# ### Sieve

# Enable the Dovecot sieve plugin which let's users run scripts that process
# mail as it comes in.
sed -i "s/#mail_plugins = .*/mail_plugins = \$mail_plugins sieve/" /etc/dovecot/conf.d/20-lmtp.conf

# Configure sieve. We'll create a global script that moves mail marked
# as spam by Spamassassin into the user's Spam folder.
#
# * `sieve_before`: The path to our global sieve which handles moving spam to the Spam folder.
#
# * `sieve`: The path to the user's main active script. ManageSieve will create a symbolic
# link here to the actual sieve script. It should not be in the mailbox directory
# (because then it might appear as a folder) and it should not be in the sieve_dir
# (because then I suppose it might appear to the user as one of their scripts).
# * `sieve_dir`: Directory for :personal include scripts for the include extension. This
# is also where the ManageSieve service stores the user's scripts.
cat > /etc/dovecot/conf.d/99-local-sieve.conf << EOF;
plugin {
  sieve_before = /etc/dovecot/sieve-spam.sieve
  sieve = $STORAGE_ROOT/mail/sieve/%d/%n.sieve
  sieve_dir = $STORAGE_ROOT/mail/sieve/%d/%n
}
EOF

# Copy the global sieve script into where we've told Dovecot to look for it. Then
# compile it. Global scripts must be compiled now because Dovecot won't have
# permission later.
sievec /etc/dovecot/sieve-spam.sieve

# PERMISSIONS

# Ensure configuration files are owned by dovecot and not world readable.
chown -R mail:dovecot /etc/dovecot
chmod -R o-rwx /etc/dovecot

# ### User Authentication

# Have Dovecot query our database, and not system users, for authentication.
sed -i "s/#*\(\!include auth-system.conf.ext\)/#\1/"  /etc/dovecot/conf.d/10-auth.conf
sed -i "s/#\(\!include auth-sql.conf.ext\)/\1/"  /etc/dovecot/conf.d/10-auth.conf

# Specify how the database is to be queried for user authentication (passdb)
# and where user mailboxes are stored (userdb).
cat > /etc/dovecot/conf.d/auth-sql.conf.ext << EOF;
passdb {
  driver = sql
  args = /etc/dovecot/dovecot-sql.conf.ext
}
userdb {
  driver = static
  args = uid=mail gid=mail home=$STORAGE_ROOT/mail/mailboxes/%d/%n
}
EOF

# Configure the SQL to query for a user's password.
cat > /etc/dovecot/dovecot-sql.conf.ext << EOF;
driver = sqlite
connect = $DB_PATH
default_pass_scheme = SHA512-CRYPT
password_query = SELECT email as user, password FROM users WHERE email='%u';
EOF
chmod 0600 /etc/dovecot/dovecot-sql.conf.ext # per Dovecot instructions

# Have Dovecot provide an authorization service that Postfix can access & use.
cat > /etc/dovecot/conf.d/99-local-auth.conf << EOF;
service auth {
  #unix_listener /var/spool/postfix/private/auth {
    #mode = 0666
    #user = postfix
    #group = postfix
  #}
  inet_listener {
    port = 12345
  }
}
EOF

# To mark mail as spam or ham, just drag it in or out of the Spam folder. We'll
# use the Dovecot antispam plugin to detect the message move operation and execute
# a shell script that invokes learning.

# Enable the Dovecot antispam plugin.
# (Be careful if we use multiple plugins later.) #NODOC
sed -i "s/#mail_plugins = .*/mail_plugins = \$mail_plugins antispam/" /etc/dovecot/conf.d/20-imap.conf
sed -i "s/#mail_plugins = .*/mail_plugins = \$mail_plugins antispam/" /etc/dovecot/conf.d/20-pop3.conf

# Configure the antispam plugin to call spamc-learn-pipe.sh.
cat > /etc/dovecot/conf.d/99-local-spampd.conf << EOF;
plugin {
    antispam_backend = pipe
    antispam_spam_pattern_ignorecase = SPAM
    antispam_allow_append_to_spam = yes
    antispam_pipe_program_spam_args = /usr/local/bin/spamc-learn-pipe.sh;--learntype=spam
    antispam_pipe_program_notspam_args = /usr/local/bin/spamc-learn-pipe.sh;--learntype=ham
    antispam_pipe_program = /bin/bash
}
EOF

# Have Dovecot run its mail process with a supplementary group (the spampd group)
# so that it can access the learning files.

# FIXME
#$TOOLS_DIR/editconf.py /etc/dovecot/conf.d/10-mail.conf \
	#mail_access_groups=spampd

# Here's the script that the antispam plugin executes. It spools the message into
# a temporary file and then runs spamc on it.
# from http://wiki2.dovecot.org/Plugins/Antispam
cat > /usr/local/bin/spamc-learn-pipe.sh << EOF;
cat<&0 >> /tmp/sendmail-msg-\$\$.txt
/usr/bin/spamc -d \$SPAMASSASSIN_1_PORT_10025_TCP_ADDR \$* /tmp/sendmail-msg-\$\$.txt > /dev/null
rm -f /tmp/sendmail-msg-\$\$.txt
exit 0
EOF
chmod a+x /usr/local/bin/spamc-learn-pipe.sh

# Configure the doveadm service to listen
cat > /etc/dovecot/conf.d/99-remote-doveadm.conf << EOF;
service doveadm {
    inet_listener {
        # port to listen on
        port = 1234
        # enable SSL
        #ssl = yes
    }
}
EOF
