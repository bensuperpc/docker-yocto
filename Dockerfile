ARG DOCKER_IMAGE=debian:bookworm
FROM ${DOCKER_IMAGE} as builder

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG en_US.utf8
ENV LC_ALL en_US.UTF-8

RUN apt-get update && apt-get -y install \
# All needed packages for building yocto images
	gcc build-essential \
	gawk wget git diffstat unzip texinfo chrpath socat cpio xz-utils debianutils iputils-ping libegl1-mesa \
	python3 python3-pip python3-pexpect python3-subunit pylint python3-git python3-jinja2 \
	libsdl1.2-dev xterm mesa-common-dev zstd liblz4-tool lz4 zstd unzip xz-utils \
	x11-utils xvfb \
	ccache ninja-build cmake distcc icecc meson \
	apt-transport-https ca-certificates gnupg2 \
	locales lsb-release rsync \
# All needed packages for running yocto images (Qemu and others)
#	qemu-system-x86 qemu-system-arm qemu-system-mips qemu-system-misc \
#	qemu-system-ppc qemu-system-sparc qemu-system-aarch64 qemu-utils \
#	qemu-kvm libvirt-clients libvirt-daemon-system \
#	bridge-utils libguestfs-tools genisoimage virtinst libosinfo-bin \
# Other packages
	bash-completion \
	&& apt-get clean \
	&& apt-get -y autoremove --purge \
	&& rm -rf /var/lib/apt/lists/*

# Install pip packages
RUN if [ "$(lsb_release -cs)" = "bookworm" ]; then \
		pip3 install --upgrade --no-cache-dir --break-system-packages git+https://github.com/cpb-/yocto-cooker.git; \
	else \
		pip3 install --upgrade --no-cache-dir git+https://github.com/cpb-/yocto-cooker.git; \
	fi

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

FROM scratch as final
COPY --from=builder / /
# COPY --from=builder ./app ./app

ARG BUILD_DATE
ARG VCS_REF
ARG VCS_URL="https://github.com/bensuperpc/docker-yocto"
ARG PROJECT_NAME
ARG AUTHOR="Bensuperpc"
ARG URL="https://github.com/bensuperpc"

ARG CCACHE_MAXSIZE=16G
ENV CCACHE_MAXSIZE=${CCACHE_MAXSIZE}

ARG IMAGE_VERSION="1.0.0"
ENV IMAGE_VERSION=${IMAGE_VERSION}

ENV LANG en_US.utf8
ENV LC_ALL en_US.UTF-8
ENV TERM xterm-256color

LABEL maintainer="Bensuperpc <bensuperpc@gmail.com>"
LABEL author="Bensuperpc <bensuperpc@gmail.com>"
LABEL description="A yocto docker image for building yocto project"

LABEL org.label-schema.schema-version="1.0" \
	  org.label-schema.build-date=${BUILD_DATE} \
	  org.label-schema.name=${PROJECT_NAME} \
	  org.label-schema.description="yocto" \
	  org.label-schema.version=${IMAGE_VERSION} \
	  org.label-schema.vendor=${AUTHOR} \
	  org.label-schema.url=${URL} \
	  org.label-schema.vcs-url=${VCS_URL} \
	  org.label-schema.vcs-ref=${VCS_REF} \
	  org.label-schema.docker.cmd="docker build -t bensuperpc/yocto:latest -f Dockerfile ."


ARG USER_NAME=testuser
ENV HOME=/home/$USER_NAME
ARG USER_UID=1000
ARG USER_GID=1000
RUN groupadd -g $USER_GID -o $USER_NAME
RUN useradd -m -u $USER_UID -g $USER_GID -o -s /bin/bash $USER_NAME
USER $USER_NAME

WORKDIR /home/$USER_NAME

#VOLUME ["/work"]
#WORKDIR /work

#RUN cooker --version

CMD ["/bin/bash", "-l"]

