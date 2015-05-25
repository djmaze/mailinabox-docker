#!/bin/bash

kill_postgrey() {
  echo Got SIGTERM, killing PID $PID
  kill $PID
}
trap kill_postgrey SIGTERM

postgrey --daemonize --pidfile=/var/run/postgrey.pid --inet=0.0.0.0:10023

# Wait for postgrey to exit
PID=$(cat /var/run/postgrey.pid)
while [ 1 ]; do
  sleep 1
  kill -0 $PID >/dev/null 2>&1
  # Exit if postgrey is gone
  if [ $? == 1 ]; then exit; fi
done
