#!/bin/sh

envsubst '${WORKER_PROCS}' < /etc/nginx/templates/nginx.conf.template > /etc/nginx/nginx.conf
exec "$@"
