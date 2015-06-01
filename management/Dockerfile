FROM mailinabox-docker-base

RUN apt-get update
RUN apt-get -y install python3-flask links duplicity libyaml-dev python3-dnspython python3-dateutil python3-pip git dovecot-core ldnsutils

# Check out latest management app source code
RUN git clone --single-branch https://github.com/mail-in-a-box/mailinabox.git /usr/local/mailinabox

COPY setup.sh $TOOLS_DIR/setup.sh
RUN $TOOLS_DIR/setup.sh

RUN mv /usr/bin/doveadm /usr/bin/doveadm-original
COPY doveadm-wrapper /usr/bin/doveadm

COPY mail.py $TOOLS_DIR/
COPY add-initial-user /usr/local/bin/

COPY service /usr/sbin/service
RUN sed -i "s/\$NSDW_LISTEN_PORT/${NSDW_LISTEN_PORT}/" /usr/sbin/service

COPY start.sh /
ENTRYPOINT ["/start.sh"]
EXPOSE 10222/tcp
