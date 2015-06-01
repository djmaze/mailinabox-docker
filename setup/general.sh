#!/bin/bash

if [ ! -f ${STORAGE_ROOT}/doveadm/password.env ]; then
  echo DOVEADM_PASSWORD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-16}) >${STORAGE_ROOT}/doveadm/password.env
fi
