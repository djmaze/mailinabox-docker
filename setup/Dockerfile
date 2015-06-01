FROM mailinabox-docker-base

RUN apt-get -y install openssl ldnsutils

COPY general.sh /
COPY ssl.sh /
COPY dnssec.sh /

COPY start.sh /
CMD ["/start.sh"]
