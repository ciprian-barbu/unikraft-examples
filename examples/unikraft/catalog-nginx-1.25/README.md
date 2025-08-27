This is the [Nginx 1.25](https://github.com/unikraft/catalog/tree/main/library/nginx/1.25) example from the `Unikraft` catalog repository.

The files in this folder will help build the example for `qemu.x86_64` configuration. There is also a `bunnyfile` which can be used to package the built unikernel so that it can be run by `urunc`.

Here are the steps:

```console
./build.sh
./build-bunny.sh
./run-urunc.sh
```

This example generates a unikernel that uses `Unikraft's` [app-elfloader](https://github.com/unikraft/app-elfloader), which is capable of loading external applicatoins, like `nginx`.
As all the other examples in the `Unikraft` catalog, this too makes use of `Kraftfile` to define the unikernel configuration.

As it can be seen from the list of `kconfig`, this example enables [`CONFIG_LIBVFSCORE_AUTOMOUNT_CI_EINITRD`](https://github.com/unikraft/catalog/blob/main/library/nginx/1.25/Kraftfile#L98).
This means that a root filesystem will be generated, in this case the `Kraftfile` sets [`rootfs`](https://github.com/unikraft/catalog/blob/main/library/nginx/1.25/Kraftfile#L5) parameter to [`Dockerfile`](https://github.com/unikraft/catalog/blob/main/library/nginx/1.25/Dockerfile).
Furthermore, the root filesystem will be embedded in the final binary image, so no additional files are needed to run the application.

Note that the cmdline from the `bunnyfile` *must* set the same value as in the `Kraftfile`, because the `app-elfloader` needs to know the path of the application, and it reads it from the extra arguments passed from `qemu`.
