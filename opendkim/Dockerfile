FROM mailinabox-docker-base

RUN apt-get -y install openssl opendkim opendkim-tools

COPY setup.sh $TOOLS_DIR/setup.sh
RUN $TOOLS_DIR/setup.sh

COPY start.sh /
ENTRYPOINT ["/start.sh"]
EXPOSE 8891/tcp
VOLUME $STORAGE_ROOT/mail/dkim
