# docker-yocto

## _Yocto in docker_

You can build images with yocto in docker.


## Features

- Build image in docker with yocto, no need to install yocto (and all dependencies) on your host
- Multiple layers (In submodules)
- Easy to use (Makefile)

## Requirements

### Software requirements

| Software | Minimum | Recommended |
| ------ | ------ | ------ |
| Linux | Any | Any |
| Docker | 19.x | 20.x |
| Make | 4.x | 4.x |
| Time | x hours | x hours |

### Hardware requirements

| Hardware | Minimum | Recommended |
| ------ | ------ | ------ |
| CPU | 2 cores | 8 cores |
| GPU | - | - |
| Disk space | HDD 50 GB | SSD 300 GB |
| Internet | 10 Mbps | 100 Mbps |

### Tested on

With this configuration, you can build a core-image-full-cmdline for intel-corei7-64 in 1h30-2h00.

- AMD Ryzen 7 5800H (8 cores/16 threads at 3.2 GHz/4.4 GHz)
- 32 GB RAM
- 1 TB SSD NVMe Samsung 980 Pro
- 100 Mbps internet
- Manjaro Linux
- Yocto 4.2 beta (02/2023)

## How to use docker-yocto

Clone this repository

```sh
git clone --recurse-submodules --remote-submodules https://github.com/bensuperpc/docker-yocto.git
```

Checkout the branch you want (**For each submodules/layers**).
**All branches must be the same version on poky/openembedded-core and other submodules/layers.**

```sh
git branch -a # show all branches on submodules/layers or poky/openembedded-core
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

With openembedded-core :

```sh
source openembedded-core/oe-init-build-env build_x86_64 
```

**Or** with poky (Not for production) :

```sh
source poky/oe-init-build-env build_x86_64 
```

Add meta-intel layer :

```sh
bitbake-layers add-layer ../../meta-intel
```

Show layers if you want :

```sh
bitbake-layers show-layers
```

Change the MACHINE in conf/local.conf :

```sh
MACHINE = "intel-corei7-64"
```

Now you can build the image :

```sh
bitbake core-image-full-cmdline
```

Now you can exit the container when the build is finished.

```sh
exit
```

All the build is in the **"builds"** directory.

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
