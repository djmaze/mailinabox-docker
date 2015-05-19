BASE_IMAGE = mailinabox-docker-base

default: base docker-compose

base: Dockerfile.base
		docker build -t ${BASE_IMAGE} -f Dockerfile.base .

docker-compose:
		docker-compose build
