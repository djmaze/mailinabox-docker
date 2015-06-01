# Mail-in-a-Box on Docker


This is a __work-in-progress__ attempt to port [Mail-in-a-Box](https://mailinabox.email/) into a Docker Compose setup. That means the services (dovecot, postfix etc.) are broken up into different containers.

The first version provides basic functionality only. It uses external DNS and provides no DNSSEC or DKIM support. Also, the management interface is not working yet.

## Getting started

(Use `sudo` as needed on your system in order to run Docker related commands.)

* Copy `.env.sample` to``.env` and edit it. Enter a primary hostname for the mail service and a primary email address. The user created will have administrative privileges.
* Cd into the `base` folder and run `make` in order to build the base image needed for all containers.
* Back in the main folder, run `docker-compose run setup`. It will generate SSL key, cert and dovecot password.
* Run `docker-compose run management add-initial-user` in order to add an initial mail user with admin privileges. You will be asked for the email address and password to create.

Run `docker-compose up -d` in order to start all services.

Use `docker-compose ps` to see which services are running.

The logs are written to the `log` subdirectory. You can optionally set the `SYSLOG_SERVER` variable in `.env` in order to route logs to a remote syslog server.

## Updating the containers

After changing Dockerfiles or any configuration, use the standard upgrade procedure for Docker Compose apps to rebuild and run the new containers:

    docker-compose build && docker-compose stop && docker-compose rm && docker-compose up -d
