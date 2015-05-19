FROM mailinabox-docker-base

RUN apt-get -y install bc dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd dovecot-sqlite sqlite3 \
    dovecot-sieve dovecot-managesieved spamc dovecot-antispam

COPY conf/sieve-spam.txt /etc/dovecot/sieve-spam.sieve
COPY setup.sh $TOOLS_DIR/setup.sh
RUN $TOOLS_DIR/setup.sh

COPY start.sh /
ENTRYPOINT ["/start.sh"]
EXPOSE 993/tcp 12345/tcp 1234/tcp
