This is the [`C Hello` on Unikraft](https://github.com/unikraft/catalog-core/tree/scripts/c-hello) example from the `Unikraft` catalog-core repository.

The files in this folder will help build the example for `qemu.x86_64` configuration. There is also a `bunnyfile` which can be used to package the built unikernel so that it can be run by `urunc`.

Here are the steps:

```console
./build.sh
./build-bunny.sh
./run-urunc.sh
```

This example generates a simple unikernel, with no `initrd` or other types of rootfs. The application is embedded in the unikernel and it takes the place of an init function.

As with all the examples in the `Unikraft` catalog-core, this example makes use of `Makefiles` and other helper script to build and run the application.

Note that the cmdline from the bunnyfile can hold any value, because the unikernel runs the main function from the `c-hello` application, so the unikernel ignores the extra arguments passed from the VMM (e.g. `qemu`).

> **_NOTE:_**  There is a unikraft-c-hello.yaml Kubernetes manifest, which can be used as example, but you need to edit the image name.
