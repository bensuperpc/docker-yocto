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
PROJECT_NAME := yocto
AUTHOR := bensuperpc
REGISTRY := docker.io

VERSION := 1.0.0

CPUS := 8.0
MEMORY := 8GB

ARCH_LIST := linux/amd64
# linux/amd64,linux/amd64/v3, linux/arm64, linux/riscv64, linux/ppc64
comma:= ,
PLATFORMS := $(subst $() $(),$(comma),$(ARCH_LIST))

IMAGE_NAME := $(PROJECT_NAME)
OUTPUT_IMAGE := $(AUTHOR)/$(IMAGE_NAME)

DOCKERFILE := Dockerfile
DOCKER := docker

# Git config
GIT_SHA := $(shell git rev-parse HEAD)
GIT_ORIGIN := $(shell git config --get remote.origin.url) 

DATE := $(shell date -u +"%Y%m%d")
UUID := $(shell uuidgen)

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
		--platform $(PLATFORMS) --progress auto \
		--tag $(OUTPUT_IMAGE):$(BASE_IMAGE_NAME)-$@-$(VERSION)-$(DATE)-$(GIT_SHA) \
		--tag $(OUTPUT_IMAGE):$(BASE_IMAGE_NAME)-$@-$(VERSION)-$(DATE) \
		--tag $(OUTPUT_IMAGE):$(BASE_IMAGE_NAME)-$@-$(VERSION) \
		--build-arg BUILD_DATE=$(DATE) --build-arg DOCKER_IMAGE=$(BASE_IMAGE_NAME):$@ \
		--build-arg VERSION=$(VERSION) --build-arg PROJECT_NAME=$(PROJECT_NAME) \
		--build-arg VCS_REF=$(GIT_SHA) --build-arg VCS_URL=$(GIT_ORIGIN)
		

.SECONDEXPANSION:
$(addsuffix .run,$(BASE_IMAGE_TAGS)): $$(basename $$@)
	$(DOCKER) run -it --rm --workdir /work --user $(shell id -u ${USER}):$(shell id -g ${USER}) \
		--security-opt no-new-privileges --read-only \
		--mount type=bind,source=$(shell pwd),target=/work \
		--mount type=tmpfs,target=/tmp,tmpfs-mode=1777,tmpfs-size=4G \
		--platform $(PLATFORMS) \
		--cpus $(CPUS) --memory $(MEMORY) \
		--name $(IMAGE_NAME)-$(BASE_IMAGE_NAME)-$(basename $@)-$(DATE)-$(UUID) \
		$(OUTPUT_IMAGE):$(BASE_IMAGE_NAME)-$(basename $@)-$(VERSION)-$(DATE)-$(GIT_SHA)

#  --cap-drop ALL --cap-add SYS_PTRACE

.SECONDEXPANSION:
$(addsuffix .test,$(BASE_IMAGE_TAGS)): $$(basename $$@)
	$(DOCKER) run --rm --workdir /work --user $(shell id -u ${USER}):$(shell id -g ${USER}) \
		--security-opt no-new-privileges --read-only \
		--mount type=bind,source=$(shell pwd),target=/work \
		--mount type=tmpfs,target=/tmp,tmpfs-mode=1777,tmpfs-size=4G \
		--platform $(PLATFORMS) \
		--cpus $(CPUS) --memory $(MEMORY) \
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



# https://stackoverflow.com/questions/74707530/docker-buildx-fails-to-show-result-in-image-list
# /\s*#\s*include\s*([<"])([^>"]+)([>"])/gm