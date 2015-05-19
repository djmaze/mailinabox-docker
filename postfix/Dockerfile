FROM mailinabox-docker-base

RUN apt-get -y install postfix postfix-pcre ca-certificates

COPY conf/postfix_outgoing_mail_header_filters /etc/postfix/outgoing_mail_header_filters
COPY setup.sh $TOOLS_DIR/setup.sh
RUN $TOOLS_DIR/setup.sh

RUN bash -c \
  'FILES="localtime services resolv.conf hosts nsswitch.conf"; \
  for file in $FILES; do  \
      cp /etc/${file} /var/spool/postfix/etc/${file}; \
      chmod a+rX /var/spool/postfix/etc/${file} \
      ; \
  done'

COPY start.sh /
ENTRYPOINT ["/start.sh"]
EXPOSE 25/tcp 587/tcp
