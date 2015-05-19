FROM mailinabox-docker-base

RUN apt-get -y install postgrey

ENTRYPOINT ["postgrey", "--inet=0.0.0.0:10023"]
EXPOSE 10023/tcp
# FIXME Maybe persist this in a data/mail subfolder?
VOLUME ["/var/lib/postgrey"]
