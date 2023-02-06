# docker-yocto

## _Yocto in docker_

docker-yocto is yocto in docker.

## Features

- Esay to use

## Requirements

- Linux system (tested on Ubuntu 20.04 and Archlinux)
- Docker
- Makefile
- Internet connection
- Patience (or powerfull computer)

## How to use docker-yocto

Clone this repository

```sh
git clone --recurse-submodules --remote-submodules https://github.com/bensuperpc/docker-yocto.git
```

Checkout the branch you want (**For each submodules/layers**).
**All branches must be the same on poky/openembedded-core and other submodules/layers.**

```sh
git branch -a # show all branches
git checkout -t origin/langdale -b my-langdale # checkout the branch and create a new branch
```

### Build with docker

```sh
make build
```

### Start the container

Now you can start the container, it will mount the current directory in the container.

```sh
make start
```

### Build with yocto

Now you are in the container, you can build image with yocto.
Initialize the Build Environment, it will create a build directory.

With poky :

```sh
source poky/oe-init-build-env build_x86_64 
```

Or with openembedded-core :

```sh
source openembedded-core/oe-init-build-env build_x86_64 
```

Add meta-intel layer

With poky or openembedded-core :

```sh
bitbake-layers add-layer ../../meta-intel
```

Show layers if you want

```sh
bitbake-layers show-layers
```

Now you can build !

```sh
bitbake core-image-full-cmdline
```

Now you can exit the container when the build is finished.

```sh
exit
```

## Update submodules and base debian image

```sh
make update
```

## Useful links

- [Layerindex](https://layers.openembedded.org/layerindex/branch/master/layers/)

## Tech

- [yocto](https://www.yoctoproject.org)

## License

MIT
