NAME = mgor/ubuntu-network-manager-wireguard-builder
HOSTNAME = network-manager-wireguard-builder

.PHONY = all build run clean

USER_ID := $(shell id -u)
GROUP_ID := $(shell id -g)

ifndef RELEASE
	RELEASE := $(shell lsb_release -cs)
endif

all: build clean run

build:
	docker pull mgor/docker-ubuntu-pkg-builder:$(RELEASE)
	docker image build --build-arg RELEASE=$(RELEASE) -t $(NAME) .

run:
	docker run --rm --name $(HOSTNAME) --hostname $(HOSTNAME) -v $(CURDIR)/packages:/usr/local/src --env USER_ID=$(USER_ID) --env GROUP_ID=$(GROUP_ID) -it $(NAME)

clean:
	rm -rf $(CURDIR)/packages/* Dockerfile
