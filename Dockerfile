# syntax=docker/dockerfile:1
ARG DOCKER_IMAGE=debian:bookworm
FROM $DOCKER_IMAGE as builder

ARG VERSION="1.0.0"
ENV VERSION=$VERSION

ARG BUILD_DATE
ARG VCS_REF
ARG VCS_URL="https://github.com/bensuperpc/docker-yocto"
ARG PROJECT_NAME

LABEL maintainer="Bensuperpc <bensuperpc@gmail.com>"
LABEL author="Bensuperpc <bensuperpc@gmail.com>"
LABEL description="A yocto docker image for building yocto project"

LABEL org.label-schema.schema-version="1.0" \
	  org.label-schema.build-date=$BUILD_DATE \
	  org.label-schema.name=$PROJECT_NAME \
	  org.label-schema.description="yocto" \
	  org.label-schema.version=$VERSION \
	  org.label-schema.vendor="bensuperpc" \
	  org.label-schema.url="" \
	  org.label-schema.vcs-url=$VCS_URL \
	  org.label-schema.vcs-ref=$VCS_REF \
	  org.label-schema.docker.cmd="docker build -t bensuperpc/yocto:latest -f Dockerfile ."

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get -y install \
# All needed packages for building yocto images
	gcc build-essential \
	gawk wget git diffstat unzip texinfo chrpath socat cpio xz-utils debianutils iputils-ping libegl1-mesa \
	python3 python3-pip python3-pexpect python3-subunit pylint python3-git python3-jinja2 \
	libsdl1.2-dev xterm mesa-common-dev zstd liblz4-tool lz4 zstd unzip xz-utils \
	x11-utils xvfb \
	ccache ninja-build cmake distcc icecc meson \
	apt-transport-https ca-certificates gnupg2 \
	locales \
# All needed packages for running yocto images (Qemu and others)
	qemu-system-x86 qemu-system-arm qemu-system-mips qemu-system-misc \
	qemu-system-ppc qemu-system-sparc qemu-system-aarch64 qemu-utils \
	qemu-kvm libvirt-clients libvirt-daemon-system \
	bridge-utils libguestfs-tools genisoimage virtinst libosinfo-bin \
# Other packages
	bash-completion htop btop \
	&& apt-get clean \
	&& apt-get -y autoremove --purge \
	&& rm -rf /var/lib/apt/lists/*

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen
ENV LANG en_US.utf8

FROM builder as final
# COPY --from=builder ./app ./app

#VOLUME ["/work"]
#WORKDIR /work

#ENV HOME=/home/yocto
#RUN useradd -s /bin/bash yocto

CMD ["/bin/bash", "-i"]

