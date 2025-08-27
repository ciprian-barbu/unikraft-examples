[TOC]

## About

This guide explains how to build a Unikraft unikernel in a few different use cases, and how to package them so that `urunc` can run them.

Each of the following chapter presents some important aspect of Unikraft and offers additional selected documentation for some deep-dive reading.
Later in this guide you will find important information related to running Unikraft unikernels with [`urunc`](https://github.com/urunc-dev/urunc/) and more specifically for `k3s` with `urunc` runtime class.

However, if you are new to Unikraft and unikernel technology in general and you want to get your hands dirty quickly, it is best to follow through this guide and worry about the details later.
If instead you want to take a more structured approach to learning Unikraft and you have the necessary time for this endeavour, you should start by following the resources mentioned in the next chapter, [Introduction to Unikraft](#introduction-to-unikraft).

If you want to jump straight to building and running `Unikraft` unikernels, you can look at the catalog of examples, described in the section called [The ORCHIDE Catalog](#the-orchide-catalog).

## Introduction to Unikraft

If you are not familiar with the concept of a unikernel or you whish to refresh your knowledge and dive deeper into the subject, it is highly recommended to start with the official Unikraft documentation.
Here are some selected linked chapters to get you started with the basics of unikernel technology:

* [Welcome to Unikraft's Documentation](https://unikraft.org/docs/getting-started)
* [Unikraft Introduction](https://unikraft.org/docs/concepts) 
* [Design principles](https://unikraft.org/docs/concepts/design-principles)
* [Architecture](https://unikraft.org/docs/internals/architecture)
* [Introduction to Unikernels and Unikraft](https://unikraft.org/guides/intro)
* [Baby steps - Unikraft Internals](https://unikraft.org/guides/internals)
* [Booting](https://unikraft.org/docs/internals/booting)
* [Unikraft Guides](https://unikraft.org/guides)

### Unikraft basic concepts

Below is a picture showing the high level comparison between traditional VMs, Containers and Unikernel usecases, which can be found on the aforementioned documentation.

![High-level comparison of the SW components of traditional VMs (a), containers (b), containers in VMS (c) with unikernels (d)!](/assets/images/vm-container-unikernel.svg){width=700px}

As a brief summary, a unikernel is a single address space binary object, with no clear separation between kernel and user address spaces which allows for much faster execution.
Unikernels are specifically designed to be used in cloud environments, ofering the isolation characteristics of classical VMs, while keeping the size of the application and execution speeds similar to containers.

Key features:

* single address space
* fully modular system
* single protection level
* static linking
* POSIX support
* platform abstraction

### Unikraft architecture

The figure below is an overview of Unikraft architecture taken from the [Architecture](https://unikraft.org/docs/internals/architecture) guide.
It shows the different blocks that make up a Unikraft application, organized in different layers, Platform layer, OS primitives layer, POSIX layer and libc layer.

![Unikraft Architecture!](/assets/images/unikraft-architecture.svg){width=800px}

As such, you can look at a Unikraft unikernel as two-part unit.

The bottom part makes up the base OS-like functionality, which deals with interacting with the virtualized HW, using traditional OS concepts, such as interrupt service routines, memory management, scheduler, processes etc.
All of this is needed because unikernels are intended to run in an isolated environment, like a virtual machine.
It also provides POSIX compatibility layer and a libc layer, which is actually optional, depending on the needs of the user.

The upper part is the user application, which implements the needed functionality. The application can be very lightweight in terms of library dependencies, running more or less some number-crunching type of workload.
In other usecase, it can be more like a traditional application, for example Nginx, Redis, SQLite, which rely on heavy support from the underlying environment for processing large data from the network, and make use of all the system-calls available on traditional operating systems.


### Unikraft Boot Sequence

This chapter references information from the [Booting](https://unikraft.org/docs/internals/booting) internals guide.

Because a unikernel is basically a self contained operating system, it is important to understand what happens from the moment the unikernel is started all the way to the first instruction in the user application.

The boot sequence depends on the selected platform, like `qemu` or `firecracker`.
As described in the [Booting](https://unikraft.org/docs/internals/booting) guide, Unikraft performs a series of operations to prepare the machine for running the Unikraft core and to then run the user application.
This includes things like intializing the CPU, the memory, peripherals, installing Interrupt Service Routines and preparing the scheduler for running user processes.

After the last architecture dependent step is executed (i.e. [`_ukplat_entry`](https://github.com/unikraft/unikraft/blob/efb5069d27d539a6eb31b880b45168eb8d83160d/plat/kvm/x86/setup.c#L42)), the booting continues in the bootstrapper library, [`ukboot`](https://github.com/unikraft/unikraft/blob/efb5069d27d539a6eb31b880b45168eb8d83160d/lib/ukboot/boot.c#L394), where constructors and initializers are called.

These constructors and initializers enable various components of Unikraft to install processing routines into various moments of the boot process.
For example, a constructor is used to install the device driver for the `9pfs` virtio driver.
As another example, the [`app-elfloader`](https://github.com/unikraft/app-elfloader) library, which will be described later, uses an initializer of type `uk_late_initcall` to have Unikraft's `ukboot` component perform late initialization needed by `app-elfloader`.

After the init constructors have been called, `ukboot` will call the `main` function which, dependin on the type of build, can be provided by different sources:

* A support library, like [`app-elfloader`](https://github.com/unikraft/app-elfloader) or [`lib-wamr`](https://github.com/unikraft/lib-wamr)
* The user application code, if it implemets the `main` function
* The `ukboot` `__weak main` function, if no other object defined a `main` function

## Building a `Unikraft` unikernel

This chapter refers to the following chapters in Unikraft documentation:

* [Building a unikernel](https://unikraft.org/docs/cli/building)

Fundamentely, there are two different ways in which a Unikraft unikernel can be built:

1. To compile code natively against the Unikraft library Operating System where the user-level application code is written in a compile-time language, like C, Go or Rust.
2. To use a "loader" which accepts arbitrary user code or binaries which is executed on top of an existing, pre-built unikernel.

In order to understand the difference between these approaches it is useful to look at the lifecycle of the unikernel, from the early beginning to the point where the user application is run.

From a practical perspective, building a Unikraft unikernel and application can be done in several ways, which will be described further down below. 

### The Unikraft catalog-core way

The [`catalog-core`](https://github.com/unikraft/catalog-core/tree/scripts) is a collection of example applications which is intended for advanced developers and `Unikraft` core developers, who wish to dwelve into the internals of `Unikraft`.
This chapter references the following Unikraft information:

* [Overview](https://unikraft.org/guides/overview)
* [catalog-core](https://github.com/unikraft/catalog-core/tree/scripts)

The repository contains a top `setup.sh` script which clones the core Unikraft resources main [`unikraft`](https://github.com/unikraft/unikraft) and [`library repositories`](https://github.com/search?q=topic%3Alibrary+org%3Aunikraft&type=Repositories), to a specific location to be used by the examples.
Then, each example in the `catalog-core` is organized into a common structure which will be exemplified by looking at the [`nginx`](https://github.com/unikraft/catalog-core/tree/scripts/nginx) example:

* [`README.md`](https://github.com/unikraft/catalog-core/blob/scripts/nginx/README.md)
* [`NOTES.md`](https://github.com/unikraft/catalog-core/blob/scripts/nginx/NOTES.md)
* [`setup.sh`](https://github.com/unikraft/catalog-core/blob/scripts/nginx/setup.sh) - a script which checks if all the dependencies exist, creates a `workdir` and symlinks to the needed libraries
* [`Makefile`](https://github.com/unikraft/catalog-core/blob/scripts/nginx/Makefile) - main Makefile, which makes use of the main [`Unikraft Makefile`](https://github.com/unikraft/unikraft/blob/stable/Makefile)
* [`Makefile.uk`](https://github.com/unikraft/catalog-core/blob/scripts/nginx/Makefile.uk) - application specific Makefile, which uses specific variables names to include source code files and libraries
* [`Confik.uk`](https://github.com/unikraft/catalog-core/blob/scripts/nginx/Config.uk) - this file instructs Unikraft to configure the selected Kconfigs, and their dependencies
* [`scripts`](https://github.com/unikraft/catalog-core/tree/scripts/nginx/scripts) - collection of scripts and defconfigs for building and running the example, on different platforms (e.g. qemu, firecracker or xen)
* [`rootfs`](https://github.com/unikraft/catalog-core/tree/scripts/nginx/rootfs/) - raw rootfs structure, which is not defined by all example but needed for `nginx` to include configuration files

It's worth mentioning that the `nginx` example depends on the Unikraft [`lib-nginx`](https://github.com/unikraft/lib-nginx), which acts as an adaptation code between upstream [`nginx`](https://github.com/nginx/nginx) and `Unikraft`.
During the build step, a stable version of nginx is downloaded, patches are applied and the `main` function is renamed to `nginx_main`. This is needed so that the actual `main` function that Unikraft calls will be the one provided by `lib-nginx`.

This build method is mostly too low-level for most of the application developers, and it doesn't use the `kraftkit` tools described later in this document.
However, using these examples can be useful as a base starting point for developers who want to understand the internals of the build systems to the bone, with no extra tools or frills on top to obscure the overall view.

Other examples worth mentioning are:

* [`cpp-hello`](https://github.com/unikraft/catalog-core/tree/scripts/cpp-hello)
* [`python3-hello`](https://github.com/unikraft/catalog-core/blob/scripts/python3-hello/Makefile)
* [`elfloader-basic`](https://github.com/unikraft/catalog-core/tree/scripts/elfloader-basic)

As a conclusion, here are the steps to build and run the nginx sample application.

First install the tools needed, e.g. for a Debian based system:

```console
sudo apt install -y --no-install-recommends \
        build-essential \
        sudo \
        curl wget unzip \
        gcc-aarch64-linux-gnu \
        libncurses-dev \
        libyaml-dev \
        flex \
        bison \
        git \
        wget \
        uuid-runtime \
        qemu-kvm \
        qemu-system-x86 \
        qemu-system-arm \
        sgabios

sudo mkdir /etc/qemu/
echo "allow all" | sudo tee /etc/qemu/bridge.conf
```

Next clone the repository and build the application, e.g. for qemu.x86_64:

```console
git clone https://github.com/unikraft/catalog-core -b scripts
cd catalog-core
./setup.sh
cd nginx
./setup.sh
./scripts/build/qemu.x86_64
./scripts/run/qemu.x86_64
```

If `qemu` complains about not being able to setup networking, you need to make sure that `bridge.conf` exist and allows all connections.
Depending on the installed location of, the configuration file could be either in `/etc/qemu/bridge.conf` or `/usr/local/qemu/bridge.conf`.

```console
sudo mkdir -p /etc/qemu
echo "allow all" | sudo tee /etc/qemu/bridge.conf
```

### The `kraftkit` way

This chapter references the following resources:

* [Initializing a project with a `Kraftfile`](https://unikraft.org/docs/cli/building#initializing-a-project-with-a-kraftfile)
* [Kraftfile reference (v0.6)](https://unikraft.org/docs/cli/reference/kraftfile/v0.6)
* [kraftkit](https://github.com/unikraft/kraftkit)
* [catalog](https://github.com/unikraft/catalog)

Most of the `Unikraft` information will mention the use of `kraftkit` and `Kraftfiles` for building user applications on top of Unikraft.
Using `kraftkit` is a fast and sure way of building `Unikraft` unikernels, and there are many examples available in the `Unikraft` [catalog](https://github.com/unikraft/catalog) repository.

In very short terms the workflow for using `kraftkit` is as follows:

* Install `kraftkit` on your development environment
* Write your application
* Create a `Kraftfile`, either from scratch or based on an example
* Configure options using `kraft menu`
* Build the unikernel using `kraft build`
* Test the unikernel using `kraft run`

#### Installing `kraftkit`

The central tool to working with Unikraft is the [`kraft`](https://unikraft.org/docs/cli/reference/kraft) tool. This provides the functionality to both build Unikernels and run them in a simple and controlled fashion.

Here is a list of selected resources on the topic of the `kraft` tool:

* [Unikraft CLI companion Tool](https://unikraft.org/docs/cli)
* [kraft CLI reference](https://unikraft.org/docs/cli/reference/kraft)
* [kraft installation](https://unikraft.org/docs/cli/install)
* [Unikraft Overview Guide](https://unikraft.org/guides/overview) - part of [Unikraft guides](https://unikraft.org/guides)

It is recommended to use a recent version of Ubuntu for a smooth experience. Installing `kraft` is covered in the resources mentioned above, for example the [Installation](https://unikraft.org/docs/cli/install) guide.

#### Writing a `Kraftfile`

A Kraftfile is used to configure, build and package a Unikraft unikernel.
The format of a `Kraftfile` is describede in the [Unikraft Kraftfile Reference](https://unikraft.org/docs/cli/reference/kraftfile/).

There are many examples of `Kraftfiles` available in the [catalog](https://github.com/unikraft/catalog) repository. In the next section we will cover two approaches and present relevant examples to look out.

#### Using `Kraftfile` and Makefiles

This section refers to the following resources:

* [Compiling and linking your application with Unikraft](https://unikraft.org/docs/cli/building#compiling-and-linking-your-application-with-unikraft)
* [Internals of the Build Process](https://unikraft.org/docs/internals/build-system)
* [Hello World](https://github.com/unikraft/catalog/tree/main/library/helloworld)
* [Simple C HTTP Server](https://github.com/unikraft/catalog/tree/main/native/http-c)

Essentially this approach describes the most common approach of building Unikraft unikernels, using a `Kraftile` and `kraft` for defining the Unikraft environment, together with a `Makefile.uk` for defining how the user application will be built.
In the next section we will look at a slightly different approach.

##### Native C example

A relevant example for this approach is the [Hello World](https://github.com/unikraft/catalog/tree/main/library/helloworld) example from the Unikraft catalog, which is built in native mode, so without relying on the `app-elfloader`.
Looking at the `Kraftfile`, there isn't much going on, just the spec version, the name of the application, unikraft version and targets:

```yaml
spec: v0.6

name: helloworld

unikraft: stable

targets:
- qemu/x86_64
- qemu/arm64
- fc/x86_64
- xen/x86_64
```

The `Makefile.uk` is also pretty straightforward, using the Linux Kernel approach of "Goal definitions". The syntax of the `Makefile.uk` is described in more detail in [`Makefile.uk`](https://unikraft.org/docs/internals/build-system#makefileuk).
For now it is enough to notice that this example only has one source file, `main.c`:

```Makefile
$(eval $(call addlib,apphelloworld))

APPHELLOWORLD_SRCS-y += $(APPHELLOWORLD_BASE)/main.c
```

To build and try this example, the steps are the following, assuming you have already installed `kraft`:

```console
git clone https://github.com/unikraft/catalog
cd catalog/library/helloworld
kraft build --arch x86_64 --plat qemu
kraft run
```

You will notice that the build step will compile many files, which make up the `Unikraft` runtime.
After the build is finished, a `.config.helloworld_qemu-x86_64` file is generated, which lists all the relevant `Kconfig` values generated for this example.
More `Kconfig` variables can be set in the `Kraftfile`, according to the [Unikraft Kraftfile Reference](https://unikraft.org/docs/cli/reference/kraftfile/).

##### Native C HTTP server

Another example worth exploring is the [Simple C HTTP Server](https://github.com/unikraft/catalog/tree/main/native/http-c), because it follows the same approach, but it also configures networking via the Unikraft port of [`lib-lwip`](https://github.com/unikraft/lib-lwip).
As such, this can serve as a better starting point for more complex unikernels which require networking.

##### Native C++ "Hello World"

The next example is interesting because it utilizes the `Unikraft` [`lib-libcxx`](https://github.com/unikraft/lib-libcxx) support library. This implements the `C++` runtime, which is not part of `Unikraft` core.
Without this library, the application cannot be run.

Here are the steps to build the sample application [C++ "Hello, World!"](https://github.com/unikraft/catalog/tree/main/native/helloworld-cpp):


```console
git clone https://github.com/unikraft/catalog
cd native/helloworld-cpp
kraft build --arch x86_64 --plat qemu
kraft run
```

#### Building applications in Docker containers

In the Unikraft [catalog](https://github.com/unikraft/catalog) you will find many examples which contain a `Dockerfile`.
These are used primarily for building a root file system (rootfs), but we will cover this topic in a later chapter.

A common approach is to build the user application in a Docker container and then place it in the generated rootfs.
This is useful when building unikernels in `binary compatibility mode`, where the application binary can be written in any language, and then it will be loaded at run-time by [`app-elfloader`](https://github.com/unikraft/app-elfloader).
However, as it will be shown here, you are not required to use a loader. There are many possible usecase, but the goal of this chapter is to show the different options, and to remove any confusions about them.

##### Binary comptability C "Hello, World!"

For this section you can refer to the following resources for more information:
* [Packaging unikernels](https://unikraft.org/docs/cli/packaging)
* [Kraftfile reference (v0.6)](https://unikraft.org/docs/cli/reference/kraftfile/v0.6)
* [C "Hello, World!"](https://github.com/unikraft/catalog/tree/main/examples/helloworld-gcc13.2)
* [Base template](https://github.com/unikraft/catalog/blob/main/library/base)
* [Compatibility](https://unikraft.org/docs/concepts/compatibility)

The [C "Hello, World!"](https://github.com/unikraft/catalog/tree/main/examples/helloworld-gcc13.2) is the simplest example showing how to build an application outside of the Unikraft build system.
The [`Kraftfile`](https://github.com/unikraft/catalog/blob/main/examples/helloworld-gcc13.2/Kraftfile) is pretty slim and sets the following parameters:

* spec: v0.6
* name: helloworld-gcc13.2
* runtime: base:latest - this means that the base configuration is taken from the `unikraft.org/base:latest` package; you can inspect the [`Kraftfile`](https://github.com/unikraft/catalog/blob/main/library/base/Kraftfile) for this package for more information
* rootfs: ./Dockerfile - the rootfs will be built according to the contents of the Docker image generated from this `Dockerfile`
 
In the [`Dockerfile`](https://github.com/unikraft/catalog/blob/main/examples/helloworld-gcc13.2/Dockerfile) there are a few interesting things:

* it shows how the application is compiled with gcc
* the binary is created under `/helloworld`
* the argument `-fPIC` is passed to gcc, which means that it will generate position independent code; this is a requirement for building Unikraft unikernel applications
* the image is based on `scratch`
* the binary `/helloworld` is copied from the build container to the destination image under the same path; the name of the file matches the `cmd` parameter in the `Kraftfile`
* some C libraries are copied from the build container to the destination image; these are dependencies for the generated binary code

##### Binary compatibility C++ "Hello, World!"

This example can be found at [C++ "Hello, World!"](https://github.com/unikraft/catalog/tree/main/examples/helloworld-g%2B%2B13.2) with the single difference that the library dependencies for the generated binary are different, and include `libm` and `libstdc++` among others.
You can have a look at the [`Dockerfile`](https://github.com/unikraft/catalog/blob/main/examples/helloworld-g%2B%2B13.2/Dockerfile).

##### Binary compatibility Java HTTP Server

This example can be found at [Java](https://github.com/unikraft/catalog/tree/main/library/java/17).
Similarly, the application is built as part of constructing the rootfs, you can have a look at the [Dockerfile](https://github.com/unikraft/catalog/blob/main/library/java/17/Dockerfile).

This example is similar to the previous C and C++ examples, except for the programming language (Java) and the library dependencies that need to be copied in the rootfs.
It can be a good starting point should you chose to write an application in Java.

## The rootfs

This chapter references the following information from Unikraft documentation:

* [Filesystems](https://unikraft.org/docs/cli/filesystem)

Unikernels operate in highly specialized environments where resource constraints and performance optimizations are important.
The rootfs allows the user to extend the unikernel by providing essential data like configuration files, input data or even the actual user application, as it will be shown later. 

Unikraft supports essentially two classes of root filesystems:
* initial ramdisks ("initrd" or "initram")
* external volumes (using 9pfs or virtio-fd)

With Unikraft you can also combine thse options, but for this guide we will focus on a few of the possible usecases.

### No rootfs

The simplest option is to build your unikernel so that it statically links with the application, which provides the `main` function.
Many of the examples listed before actually work this way, for example the [Hello World](https://github.com/unikraft/catalog/tree/main/library/helloworld) example from the `Unikraft` catalog.

You can still opt to build a rootfs (e.g. add a rootfs: ./Dockerfile in your Kraftfile) but it is not required for running the actual application.

### External rootfs

This chapter references the following information from Unikraft documentation:

* [Initial Ramdisk Filesystem (initramfs)](https://unikraft.org/docs/cli/filesystem#initial-ramdisk-filesystem-initramfs)
* [Top-level `rootfs` attribute](https://unikraft.org/docs/cli/reference/kraftfile/v0.6#top-level-rootfs-attribute)


When using a `kraftkit`, a rootfs can be defined in the `Kraftfile`'s rootfs section, as described in the [Top-level `rootfs` attribute](https://unikraft.org/docs/cli/reference/kraftfile/v0.6#top-level-rootfs-attribute).
It is important to note that currently `Unikraft` can only generate rootfs in a [CPIO](https://en.wikipedia.org/wiki/Cpio) format. However, the seed of the rootfs can come in multiple formats.

From a simplified view, a rootfs can be used for two purposes:

1. To store the user application; this means that after the Unikraft environment is loaded the rootfs will be mounted into memory and then the command specified (e.g. in the Kraftfile) will point to the location of the user application (e.g.  the [C "Hello, World!"](https://github.com/unikraft/catalog/tree/main/examples/helloworld-gcc13.2) example)
2. Additional storage with useful data; for example when using an application like [Nginx 1.25](https://github.com/unikraft/catalog/tree/main/library/nginx/1.25) the [`Dockerfile`](https://github.com/unikraft/catalog/blob/main/library/nginx/1.25/Dockerfile) will contain things like `/etc/nginx/nginx.conf`

There are more examples available in the [Unikraft Applications & Examples Catalog](Unikraft Applications & Examples Catalog) should you wish to explore more complex usecases.


### Embedded rootfs

This chapter references the following information from Unikraft documentation:

* [Embedded Initial Ramdisk Filesystems (einitrds)](Unikraft Applications & Examples Catalog)

Having an embedded initrd as rootfs is a good way of making modular applications, where the core `Unikraft` remains unchanged, while the content of the rootfs can differ for different usecases.

The resulting binary will be bigger, to accomodate the rootfs, but on the other hand everything is packed into one single binary, without the need to pass an external rootfs.

Some good examples using this options are:

* [Redis 7.2](https://github.com/unikraft/catalog/tree/main/library/redis/7.2); this example obtains the `redis-server` binary from a Docker image and places it in the generated rootfs
* [Lua 5.4 Image](https://github.com/unikraft/catalog/tree/main/library/lua/5.4); this example creates the initrd from a raw [rootfs](https://github.com/unikraft/catalog/tree/main/library/lua/5.4/rootfs) directory which contains the user application, [helloworld.lua](https://github.com/unikraft/catalog/blob/main/library/lua/5.4/rootfs/helloworld.lua)
* [C "Hello, World!"](https://github.com/unikraft/catalog/tree/main/examples/helloworld-gcc13.2); this example builds the user application and places it in the initrd, which then will be called at runtime as specified in the [`Kraftfile`](https://github.com/unikraft/catalog/blob/main/examples/helloworld-gcc13.2/Kraftfile)

### Using external volumes

This chapter references the following information from Unikraft documentation:

* [External Volumes](https://unikraft.org/docs/cli/filesystem#external-volumes)
* [9pfs: Unikraft's 9p Virtual Filesystem](https://github.com/unikraft/unikraft/tree/staging/lib/9pfs)

Additionally, `Unikraft` supports using volumes as the root filesystem or as additional storage space mounted at runtime.
Volumes, in this context, refers to either a partition or other types of logical storage units which exist on a physical or virtual disk.

In addition, it is also possible to map a portition of the host file system inside the VM environment, by using the `9P` protocol.

## Running `Unikraft` unikernels with urunc

This chapter presents some useful information about [`urunc`](https://github.com/urunc-dev/urunc/) and how to run `Unikraft` unikernels with `urunc`. 

The goal of `urunc` is to provide a "runc for unikernels", an `OCI` runtime which is capable to run unikernels as if they were regular containers. This includes using `urunc` to run unikernels in `Kubernetes` environments.

This guide does not cover the installation of `urunc`, there are other sources of information for that topic:

* [Quickstart on urunc-dev](https://github.com/urunc-dev/urunc?tab=readme-ov-file#quick-start)
* [Quickstart on urunc.io](https://urunc.io/quickstart/)
* [Installation on urunc.io](https://urunc.io/installation/)

However, for the purpose of this guide it is highly recommended to prepare a `urunc` capable environment, for example by installing `urunc` standalone, and run the workloads using `Docker`.

### The `bunny` tool

This chapter refers to the following information pertaining to [Nubificus LTD](https://github.com/nubificus), as an legal entity or community.

* [Bunny: Build and package unikernels like containers](https://github.com/nubificus/bunny)
* [Building/Packaging unikernels](https://urunc.io/package/)

With `urunc` it is required that the unikernel is packaged in `OCI` format, but `urunc` can also read additional parameters from the `OCI` image, which are used to determine the type of unikernel, the command line arguments and other dedicated annotations.

For this purpose, the [`bunny`](https://github.com/nubificus/bunny) tool has been created to replace the now deprecated tool [`pun`](https://github.com/nubificus/pun).
This tools supports multiple unikernel types, but for the purpose of this guide we will focus on `Unikraft` only.

## The ORCHIDE catalog

The [ORCHIDE catalog](https://gitlab.cs.pub.ro/orchide/orchide-poc/orchide-catalog) contains information and resources needed to build and run different examples, primarily `Unikraft`, with the purpose of running them with urunc.

To start with, have a look at the [README.md](https://gitlab.cs.pub.ro/orchide/orchide-poc/orchide-catalog/-/blob/main/README.md?ref_type=heads) and follow the instructions there.
