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

# Base image
BASE_IMAGE_NAME := debian
BASE_IMAGE_TAGS := buster bullseye bookworm

# Output docker image
AUTHOR := bensuperpc
IMAGE_NAME := yocto
IMAGE := $(AUTHOR)/$(IMAGE_NAME)

DOCKERFILE := Dockerfile
DOCKER := docker

GIT_SHA := $(shell git rev-parse HEAD)
DATE := $(shell date -u +"%Y%m%d")
UUID := $(shell uuidgen)

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

.PHONY: $(BASE_IMAGE_TAGS)
$(BASE_IMAGE_TAGS):
	$(DOCKER) buildx build . --file $(DOCKERFILE) \
		--platform linux/amd64 --progress auto \
		-t $(IMAGE):$(BASE_IMAGE_NAME)-$(VERSION)-$@-$(DATE)-$(GIT_SHA) \
		-t $(IMAGE):$(BASE_IMAGE_NAME)-$(VERSION)-$@-$(DATE) \
		-t $(IMAGE):$(BASE_IMAGE_NAME)-$(VERSION)-$@ \
		--build-arg BUILD_DATE=$(DATE) --build-arg DOCKER_IMAGE=$(BASE_IMAGE_NAME):$@ \
		--build-arg VERSION=$(VERSION)

	$(DOCKER) run -it --rm -v "$(shell pwd):/work:rw" --workdir /work --user "$(shell id -u):$(shell id -g)" \
		--security-opt no-new-privileges \
		--platform linux/amd64 \
		--cpus $(CPUS) --memory $(MEMORY) \
		--name yocto-$(BASE_IMAGE_NAME)-$@-$(DATE)-$(UUID) \
		$(IMAGE):$(BASE_IMAGE_NAME)-$@-$(DATE)

#  --read-only --cap-drop ALL --tmpfs /tmp:exec --tmpfs /run:exec --cap-add SYS_PTRACE
#  -u $(shell id -u ${USER}):$(shell id -g ${USER})
#  --read-only --tmpfs /tmp:rw ,noexec,nosuid
# --tmpfs /tmp:noexec,nosuid,size=65536k

.SECONDEXPANSION:
$(addsuffix .test,$(BASE_IMAGE_TAGS)): $$(basename $$@)
	$(DOCKER) run --rm --name test-yocto-$(BASE_IMAGE_NAME)-$(basename $@) $(IMAGE):$(BASE_IMAGE_NAME)-$(basename $@)-$(DATE) ls

.SECONDEXPANSION:
$(addsuffix .push,$(BASE_IMAGE_TAGS)): $$(basename $$@)
	$(DOCKER) push $(IMAGE) --all-tags

$(addsuffix .pull,$(BASE_IMAGE_TAGS)): $$(basename $$@)
	$(DOCKER) pull $(BASE_IMAGE_NAME):$(basename $@)

.PHONY: clean
clean:
	$(DOCKER) images --filter='dangling=true' --format='{{.ID}}' | xargs -r $(DOCKER) rmi -f

.PHONY: purge
purge: clean
	$(DOCKER) images --filter='reference=$(IMAGE)' --format='{{.Repository}}:{{.Tag}}' | xargs -r $(DOCKER) rmi -f

.PHONY: update
update:
#   Update all submodules to latest
	git pull --recurse-submodules --all --progress --jobs=0
#   git submodule update --recursive --remote --force
#	git submodule update --init --recursive
#   Update all docker image
	$(foreach tag,$(BASE_IMAGE_TAGS),$(DOCKER) pull $(BASE_IMAGE_NAME):$(tag);)
# All docker-compose things
#	docker compose down  2>/dev/null || true
#	docker rmi -f $(docker images -f "dangling=true" -q) 2>/dev/null || true
