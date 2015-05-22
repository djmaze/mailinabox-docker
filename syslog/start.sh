#!/bin/bash

chown -R 1000:1000 /var/log
exec rsyslogd -n
