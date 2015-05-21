FROM mailinabox-docker-base

RUN apt-get -y install postgrey

# Add DNSWL.org whitelist patch from mailinabox
RUN apt-get -y install patch
COPY dnswl-whitelist.patch /tmp/
RUN patch /usr/sbin/postgrey /tmp/dnswl-whitelist.patch

ENTRYPOINT ["postgrey", "--inet=0.0.0.0:10023"]
EXPOSE 10023/tcp
# FIXME Maybe persist this in a data/mail subfolder?
VOLUME ["/var/lib/postgrey"]
