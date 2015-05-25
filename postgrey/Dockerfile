FROM mailinabox-docker-base

RUN apt-get -y install postgrey

# Add DNSWL.org whitelist patch from mailinabox
RUN apt-get -y install patch
COPY dnswl-whitelist.patch /tmp/
RUN patch /usr/sbin/postgrey /tmp/dnswl-whitelist.patch

COPY start.sh /

ENTRYPOINT ["/start.sh"]
EXPOSE 10023/tcp
# FIXME Maybe persist this in a data/mail subfolder?
VOLUME ["/var/lib/postgrey"]
