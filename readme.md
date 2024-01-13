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

```bash
git clone https://github.com/bensuperpc/docker-yocto.git
```

If you want to use submodules, you can clone with submodules.

```bash
git clone --recurse-submodules --remote-submodules https://github.com/bensuperpc/docker-yocto.git
``` 

### Build with docker

```bash
make build
```

### Start the container

Now you can start the container, it will mount the current directory in the container.

```bash
make bookworm.run
```

The table below shows the available debian versions.
buster bullseye bookworm:

| Debian | Makefile target |
| ------ | ------ |
| Bookworm | bookworm |
| bullseye | bullseye |
| buster | buster |

### Build image (With cooker)

Now you are in the container, you can build image with yocto.
You can use cooker to build image, it easy to use.
We target *base-raspberrypi4-64* build from *raspberrypi4-64.json* file.

```bash
cooker cook raspberrypi4-64.json base-raspberrypi4-64
```

You can use some options with cooker: 

| Option | Description |
| ------ | ------ |
| --download | Only download the sources and not build the image |
| --sdk | Build the SDK after the image |
| --keepgoing | Continue as much as possible after an error |
| --version | Show the version of cooker |

### Build image (With bitbake)

If you want to use bitbake, you can use it. (**You need submodules**)

Checkout the branch you want (**For each submodules/layers**).
**All branches must be the same version on poky/openembedded-core and other submodules/layers.**

```bash
git branch -a # show all branches on submodules/layers or poky/openembedded-core
git checkout -t origin/kirkstone -b my-kirkstone # checkout the branch and create a new branch
```

With openembedded-core :

```bash
source layers/openembedded-core/oe-init-build-env base-raspberrypi4-64
```

**Or** with poky :

```bash
source layers/poky/oe-init-build-env base-raspberrypi4-64 
```

Add meta layer :

```bash
bitbake-layers add-layer ../meta
```

Add meta-poky layer :

```bash
bitbake-layers add-layer ../meta-poky
```

Add meta-oe layer :

```bash
bitbake-layers add-layer ../openembedded-core/meta-oe
```

Add meta-raspberrypi layer :

```bash
bitbake-layers add-layer ../layers/meta-raspberrypi
```

Show layers if you want :

```bash
bitbake-layers show-layers
```

Change the MACHINE in conf/local.conf :

```bash
MACHINE = "raspberrypi4-64"
```

Change the DISTRO in conf/local.conf :

```bash
DISTRO = "poky"
```

Now you can build the image :

```bash
bitbake core-image-base
```

Now you can exit the container when the build is finished.

```bash
exit
```

All the build is in the **"builds"** directory.

## Update submodules and base debian image

```bash
make update
```

## Useful links

- [Layerindex](https://layers.openembedded.org/layerindex/branch/master/layers/)
- [Yocto Project Reference Manual](https://docs.yoctoproject.org/ref-manual/)
- [Cooker](https://www.blaess.fr/christophe/2022/01/13/yocto-cooker-1-3/)
- [yocto](https://www.yoctoproject.org)

## License

MIT
