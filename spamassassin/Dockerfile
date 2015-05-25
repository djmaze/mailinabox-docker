FROM mailinabox-docker-base

RUN apt-get update
RUN apt-get -y install spampd razor pyzor

COPY setup.sh $TOOLS_DIR/setup.sh
RUN $TOOLS_DIR/setup.sh

COPY start.sh /
ENTRYPOINT ["/start.sh"]
EXPOSE 10025/tcp
