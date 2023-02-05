ARG DOCKER_IMAGE=debian:bullseye
FROM $DOCKER_IMAGE

ARG VERSION="1.0.0"
ENV VERSION=$VERSION

ARG BUILD_DATE
ARG VCS_REF

LABEL maintainer="Bensuperpc <bensuperpc@gmail.com>"
LABEL author="Bensuperpc <bensuperpc@gmail.com>"
LABEL description="A yocto docker image for building yocto project"

LABEL org.label-schema.schema-version="1.0" \
	  org.label-schema.build-date=$BUILD_DATE \
	  org.label-schema.name="bensuperpc/yocto" \
	  org.label-schema.description="yocto" \
	  org.label-schema.version=$VERSION \
	  org.label-schema.vendor="bensuperpc" \
	  org.label-schema.url="" \
	  org.label-schema.vcs-url="https://github.com/bensuperpc/docker-yocto" \
	  org.label-schema.vcs-ref=$VCS_REF \
	  org.label-schema.docker.cmd="docker build -t bensuperpc/yocto:latest -f Dockerfile ."

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get -y install \
	gcc build-essential \
	gawk wget git diffstat unzip texinfo chrpath socat cpio xz-utils debianutils iputils-ping libegl1-mesa \
	python3 python3-pip python3-pexpect python3-subunit pylint3 python3-git python3-jinja2 \
	libsdl1.2-dev xterm mesa-common-dev zstd liblz4-tool \
	ccache ninja-build cmake distcc icecc \
	apt-transport-https ca-certificates gnupg2 \
	locales \
	&& apt-get -y autoremove --purge \
	&& rm -rf /var/lib/apt/lists/* \
    && update-ca-certificates 

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR /work

ENTRYPOINT ["/bin/bash"]

