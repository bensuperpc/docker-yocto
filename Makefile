#//////////////////////////////////////////////////////////////
#//   ____                                                   //
#//  | __ )  ___ _ __  ___ _   _ _ __   ___ _ __ _ __   ___  //
#//  |  _ \ / _ \ '_ \/ __| | | | '_ \ / _ \ '__| '_ \ / __| //
#//  | |_) |  __/ | | \__ \ |_| | |_) |  __/ |  | |_) | (__  //
#//  |____/ \___|_| |_|___/\__,_| .__/ \___|_|  | .__/ \___| //
#//                             |_|             |_|          //
#//////////////////////////////////////////////////////////////
#//                                                          //
#//  Script, 2022                                            //
#//  Created: 14, April, 2022                                //
#//  Modified: 04, February, 2023                            //
#//  file: -                                                 //
#//  -                                                       //
#//  Source:                                                 //
#//  OS: ALL                                                 //
#//  CPU: ALL                                                //
#//                                                          //
#//////////////////////////////////////////////////////////////

DOCKERFILE := Dockerfile
DOCKER := docker

BASE_IMAGE_NAME := debian:bullseye
IMAGE_NAME := bensuperpc/yocto

TAG := $(shell date '+%Y%m%d')-$(shell git rev-parse --short HEAD)
DATE := $(shell date '+%Y%m%d')
VERSION := 1.0.0

.PHONY: all
all: build run


.PHONY: build
build:
	$(DOCKER) build -f $(DOCKERFILE) . \
	-t $(IMAGE_NAME):latest -t $(IMAGE_NAME):$(TAG) \
	--build-arg BUILD_DATE=$(DATE) --build-arg DOCKER_IMAGE=$(BASE_IMAGE_NAME) \
	--build-arg VERSION=$(VERSION)

.PHONY: run
run:
	$(DOCKER) run -it --rm -v "$(shell pwd):/work" -w /work \
	-u $(shell id -u ${USER}):$(shell id -g ${USER}) \
	$(IMAGE_NAME):latest


.PHONY: update
update:
	git pull --recurse-submodules --all --progress
	echo $(BASE_IMAGE_NAME) | xargs -n1 $(DOCKER) pull

.PHONY: push
push:
	$(DOCKER) push $(IMAGE_NAME) --all-tags