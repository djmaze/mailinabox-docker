# Mail-in-a-Box on Docker


This is a __work-in-progress__ attempt to port [Mail-in-a-Box](https://mailinabox.email/) into a Docker Compose setup. That means the services (dovecot, postfix etc.) are broken up into different containers.

The first version provides basic functionality only. It uses external DNS and provides no DNSSEC or DKIM support. Also, the management interface is not working yet.

## Getting started

* Copy `.env.sample` to``.env` and edit it. Enter a primary hostname for the mail service and a primary email address. The user created will have administrative privileges.
* Run `make base` in order to build the base image needed for all containers.
* Run `docker-compose run setup`. You will be asked for a password which will be set for the user.

Run `docker-compose up -d` in order to start all services.

Use `docker-compose ps` to see which services are running. You can inspect the logs with `docker-compose logs`.

## Updating the containers

After changing Dockerfiles or any configuration, use the standard upgrade procedure for Docker Compose apps to rebuild and run the new containers:

    docker-compose build && docker-compose stop && docker-compose rm && docker-compose up -d
