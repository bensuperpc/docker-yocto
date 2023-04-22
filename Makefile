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
#//  Modified: 22, April, 2023                               //
#//  file: -                                                 //
#//  -                                                       //
#//  Source:                                                 //
#//  OS: ALL                                                 //
#//  CPU: ALL                                                //
#//                                                          //
#//////////////////////////////////////////////////////////////

BASE_IMAGE_NAME := debian
#BASE_IMAGE_TAGS := 10 11 12
BASE_IMAGE_TAGS := buster bullseye bookworm

AUTHOR := bensuperpc
IMAGE_NAME := yocto
IMAGE := $(AUTHOR)/$(IMAGE_NAME)

DOCKERFILE := Dockerfile
DOCKER := docker

TAG := $(shell date '+%Y%m%d')-$(shell git rev-parse --short HEAD)
DATE := $(shell date -u +"%Y-%m-%d")

VERSION := 1.0.0

CPUS := 16.0
MEMORY := 8GB

.PHONY: all all.test push clean $(BASE_IMAGE_TAGS)

all: $(BASE_IMAGE_TAGS)

all.test: $(addsuffix .test,$(BASE_IMAGE_TAGS))

test: all.test

all.push: $(addsuffix .push,$(BASE_IMAGE_TAGS))

push: all.push

all.pull: $(addsuffix .pull,$(BASE_IMAGE_TAGS))

pull: all.pull

$(BASE_IMAGE_NAME): all

$(BASE_IMAGE_TAGS):
	$(DOCKER) buildx build . --file $(DOCKERFILE) \
		--platform linux/amd64 \
		-t $(IMAGE):$(BASE_IMAGE_NAME)-$@-$(TAG) \
		-t $(IMAGE):$(BASE_IMAGE_NAME)-$@ \
		-t $(IMAGE):$(BASE_IMAGE_NAME) \
		--build-arg BUILD_DATE=$(DATE) --build-arg DOCKER_IMAGE=$(BASE_IMAGE_NAME):$@ \
		--build-arg VERSION=$(VERSION)

	$(DOCKER) run -it --rm -v "$(shell pwd):/work:rw" --workdir /work --user "$(shell id -u):$(shell id -g)" \
		--security-opt no-new-privileges \
		--cpus $(CPUS) --memory $(MEMORY) \
		$(IMAGE):$(BASE_IMAGE_NAME)-$@-$(TAG)

#  --read-only --cap-drop ALL --tmpfs /tmp:exec --tmpfs /run:exec --cap-add SYS_PTRACE
#  -u $(shell id -u ${USER}):$(shell id -g ${USER})
#  --read-only --tmpfs /tmp:rw ,noexec,nosuid
# --tmpfs /tmp:noexec,nosuid,size=65536k

.SECONDEXPANSION:
$(addsuffix .test,$(BASE_IMAGE_TAGS)): $$(basename $$@)
	$(DOCKER) run --rm --name test-yocto-$(BASE_IMAGE_NAME)-$(basename $@) $(IMAGE):$(BASE_IMAGE_NAME)-$(basename $@)-$(TAG) ls

.SECONDEXPANSION:
$(addsuffix .push,$(BASE_IMAGE_TAGS)): $$(basename $$@)
	$(DOCKER) push $(IMAGE) --all-tags

$(addsuffix .pull,$(BASE_IMAGE_TAGS)): $$(basename $$@)
	$(DOCKER) pull $(BASE_IMAGE_NAME):$(basename $@)

clean:
	$(DOCKER) images --filter='reference=$(IMAGE)' --format='{{.Repository}}:{{.Tag}}' | xargs -r $(DOCKER) rmi -f

.PHONY: update
update:
	git pull --recurse-submodules --all --progress
#	git submodule update --init --recursive
#	git submodule foreach --recursive git pull --all --recurse-submodules
	echo $(BASE_IMAGE_NAME):$(BASE_IMAGE_TAGS) | xargs -n1 $(DOCKER) pull

