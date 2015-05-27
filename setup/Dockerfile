FROM mailinabox-docker-base

RUN apt-get -y install openssl

COPY ssl.sh /
COPY mail.sh /
COPY start.sh /
CMD ["/start.sh"]
