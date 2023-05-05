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

# Output docker image
PROJECT_NAME := yocto
AUTHOR := bensuperpc
REGISTRY := docker.io
WEB_SITE := bensuperpc.org

# Base image
BASE_IMAGE_NAME := debian
BASE_IMAGE_TAGS := buster bullseye bookworm

VERSION := 1.0.0

# Max CPU and memory
CPUS := 8.0
MEMORY := 8GB
MEMORY_RESERVATION := 1GB

ARCH_LIST := linux/amd64
# linux/amd64,linux/amd64/v3, linux/arm64, linux/riscv64, linux/ppc64
comma:= ,
PLATFORMS := $(subst $() $(),$(comma),$(ARCH_LIST))

IMAGE_NAME := $(PROJECT_NAME)
OUTPUT_IMAGE := $(AUTHOR)/$(IMAGE_NAME)

# Docker config
DOCKERFILE := Dockerfile
DOCKER := docker
DOCKER_DRIVER := --load
# --push

# Git config
GIT_SHA := $(shell git rev-parse HEAD)
GIT_ORIGIN := $(shell git config --get remote.origin.url) 

DATE := $(shell date -u +"%Y%m%d")
UUID := $(shell uuidgen)

.PHONY: all test push pull

all: $(BASE_IMAGE_TAGS)

test: $(addsuffix .test,$(BASE_IMAGE_TAGS))

push: $(addsuffix .push,$(BASE_IMAGE_TAGS))

pull: $(addsuffix .pull,$(BASE_IMAGE_TAGS))

.PHONY: $(BASE_IMAGE_TAGS)
$(BASE_IMAGE_TAGS): $(Dockerfile)
	$(DOCKER) buildx build . --file $(DOCKERFILE) \
		--platform $(PLATFORMS) --progress auto \
		--tag $(OUTPUT_IMAGE):$(BASE_IMAGE_NAME)-$@-$(VERSION)-$(DATE)-$(GIT_SHA) \
		--tag $(OUTPUT_IMAGE):$(BASE_IMAGE_NAME)-$@-$(VERSION)-$(DATE) \
		--tag $(OUTPUT_IMAGE):$(BASE_IMAGE_NAME)-$@-$(VERSION) \
		--tag $(OUTPUT_IMAGE):$(BASE_IMAGE_NAME)-$@ \
		--build-arg BUILD_DATE=$(DATE) --build-arg DOCKER_IMAGE=$(BASE_IMAGE_NAME):$@ \
		--build-arg VERSION=$(VERSION) --build-arg PROJECT_NAME=$(PROJECT_NAME) \
		--build-arg VCS_REF=$(GIT_SHA) --build-arg VCS_URL=$(GIT_ORIGIN) \
		--build-arg AUTHOR=$(AUTHOR) --build-arg URL=$(WEBSITE) $(DOCKER_DRIVER)
		

.SECONDEXPANSION:
$(addsuffix .run,$(BASE_IMAGE_TAGS)): $$(basename $$@)
	$(DOCKER) run -it --rm --workdir /work --user $(shell id -u ${USER}):$(shell id -g ${USER}) \
		--security-opt no-new-privileges --read-only \
		--mount type=bind,source=$(shell pwd),target=/work \
		--mount type=tmpfs,target=/tmp,tmpfs-mode=1777,tmpfs-size=4G \
		--platform $(PLATFORMS) \
		--cpus $(CPUS) --memory $(MEMORY) --memory-reservation $(MEMORY_RESERVATION) \
		--name $(IMAGE_NAME)-$(BASE_IMAGE_NAME)-$(basename $@)-$(DATE)-$(UUID) \
		$(OUTPUT_IMAGE):$(BASE_IMAGE_NAME)-$(basename $@)-$(VERSION)-$(DATE)-$(GIT_SHA)

#  --cap-drop ALL --cap-add SYS_PTRACE 		--device=/dev/kvm

.SECONDEXPANSION:
$(addsuffix .test,$(BASE_IMAGE_TAGS)): $$(basename $$@)
	$(DOCKER) run --rm --workdir /work --user $(shell id -u ${USER}):$(shell id -g ${USER}) \
		--security-opt no-new-privileges --read-only \
		--mount type=bind,source=$(shell pwd),target=/work \
		--mount type=tmpfs,target=/tmp,tmpfs-mode=1777,tmpfs-size=4G \
		--cpus $(CPUS) --memory $(MEMORY) --memory-reservation $(MEMORY_RESERVATION) \
		--name test-$(IMAGE_NAME)-$(BASE_IMAGE_NAME)-$(basename $@) \
		$(OUTPUT_IMAGE):$(BASE_IMAGE_NAME)-$(basename $@)-$(VERSION)-$(DATE)-$(GIT_SHA) ls

.SECONDEXPANSION:
$(addsuffix .push,$(BASE_IMAGE_TAGS)): $$(basename $$@)
	@echo "Pushing $(REGISTRY)/$(OUTPUT_IMAGE) with all tags"
	$(DOCKER) push $(REGISTRY)/$(OUTPUT_IMAGE) --all-tags

$(addsuffix .pull,$(BASE_IMAGE_TAGS)):
	@echo "Pulling $(BASE_IMAGE_NAME):$(basename $@)" 
	$(DOCKER) pull $(BASE_IMAGE_NAME):$(basename $@)

.PHONY: clean
clean:
	@echo "Clean all untagged images"
	$(DOCKER) images --filter='dangling=true' --format='{{.ID}}' | xargs -r $(DOCKER) rmi -f

.PHONY: purge
purge: clean
	@echo "Remove all $(OUTPUT_IMAGE) images and tags"
	$(DOCKER) images --filter='reference=$(OUTPUT_IMAGE)' --format='{{.Repository}}:{{.Tag}}' | xargs -r $(DOCKER) rmi -f

.PHONY: update
update:
#   Update all submodules to latest
#	git submodule update --init --recursive
	git pull --recurse-submodules --all --progress --jobs=0
#   git submodule update --recursive --remote --force
#   Update all docker image
	$(foreach tag,$(BASE_IMAGE_TAGS),$(DOCKER) pull $(BASE_IMAGE_NAME):$(tag);)
# All docker-compose things
#	docker compose down  2>/dev/null || true
#	docker rmi -f $(docker images -f "dangling=true" -q) 2>/dev/null || true

# https://github.com/linuxkit/linuxkit/tree/master/pkg/binfmt
qemu:
	export DOCKER_CLI_EXPERIMENTAL=enabled
	$(DOCKER) run --rm --privileged multiarch/qemu-user-static --reset -p yes
	$(DOCKER) buildx create --name qemu_builder --driver docker-container --use
	$(DOCKER) buildx inspect --bootstrap
