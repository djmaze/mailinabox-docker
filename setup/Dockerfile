FROM mailinabox-docker-base

RUN apt-get -y install openssl

COPY general.sh /
COPY ssl.sh /

COPY start.sh /
CMD ["/start.sh"]
