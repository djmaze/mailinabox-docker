FROM ubuntu:14.04

RUN apt-get update

ENV TOOLS_DIR=/build/tools
#COPY .env /tmp/build/.env
COPY tools $TOOLS_DIR

ENV STORAGE_ROOT /home/data
ENV DB_PATH ${STORAGE_ROOT}/mail/users.sqlite
ENV NSDW_LISTEN_PORT 44777
