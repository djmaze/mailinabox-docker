#!/bin/bash

chown -R 1000:1000 /var/log
if [ $SYSLOG_SERVER ]; then
  echo "*.* @$SYSLOG_SERVER;RSYSLOG_SyslogProtocol23Format" >/etc/rsyslog.d/60-remote.conf
fi

exec rsyslogd -n
