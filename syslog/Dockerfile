FROM ubuntu:14.04

RUN apt-get update
RUN apt-get install rsyslog

RUN groupadd -g 1000 user \
 && useradd -u 1000 -g 1000 user \
 && sed -i -e 's/\$PrivDropToUser syslog/\$PrivDropToUser user/' -e 's/\$PrivDropToGroup syslog/\$PrivDropToGroup user/' /etc/rsyslog.conf

COPY start.sh /start.sh

CMD ["/start.sh"]
VOLUME /dev
VOLUME /var/log

