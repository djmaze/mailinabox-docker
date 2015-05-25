FROM mailinabox-docker-base

RUN apt-get -y install opendmarc

RUN $TOOLS_DIR/editconf.py /etc/opendmarc.conf -s \
  "Syslog=true" \
  "Socket=inet:8893"

ENTRYPOINT ["opendmarc", "-f", "-c", "/etc/opendmarc.conf", "-u", "opendmarc"]
EXPOSE 8893/tcp
