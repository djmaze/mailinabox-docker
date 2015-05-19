FROM mailinabox-docker-base

RUN apt-get -y install python3-flask links duplicity libyaml-dev python3-dnspython python3-dateutil
RUN apt-get -y install python3-pip
RUN apt-get -y install git
RUN apt-get -y install dovecot-core

# Check out latest management app source code
RUN git clone --single-branch https://github.com/mail-in-a-box/mailinabox.git /usr/local/mailinabox

COPY setup.sh $TOOLS_DIR/setup.sh
RUN $TOOLS_DIR/setup.sh

RUN mv /usr/bin/doveadm /usr/bin/doveadm-original
COPY doveadm-wrapper /usr/bin/doveadm

COPY start.sh /
ENTRYPOINT ["/start.sh"]
EXPOSE 10222/tcp
