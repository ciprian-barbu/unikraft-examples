# ORCHIDE Catalog

This repository contains useful examples of unikernels which can be run with [`urunc`](https://github.com/urunc-dev/urunc).

Currently the repository contains examples from the Unikraft [catalog-core](https://github.com/unikraft/catalog-core) and [catalog](https://github.com/unikraft/catalog) repositories.
There are also a number of other useful examples which are not part of the Unikraft catalogs.

The layout of the repository looks something like this:

```console
./
├── README.md
├── deps/
│   └── unikraft/
│       ├── catalog/
│       └── catalog-core/
├── examples/
│   └── unikraft/
│       ├── catalog-core-c-hello/
│       └── catalog-nginx-1.25/
└── setup.sh*

```

In the root of the repository you will find:
* this `README.md`
* `setup.sh` - the script which intializes git submodules and sets up `Unikraft` `catalog-core`
* deps - subdir where the git submodules will be staged
* deps/unikraft/catalog - subdir where `Unikraft` [catalog](https://github.com/unikraft/catalog) will be staged
* deps/unikraft/catalog-core - subdir where `Unikraft` [catalog-core](https://github.com/unikraft/catalog-core) will be staged
* examples/unikraft - subdir which contains the `Unikraft` based examples, some of them relying on the upstream examples from `catalog` and `catalog-core`, others independent

For a detailed explanations of the examples, jump to the section below called [Examples](#examples).

## Getting started

In the root of this repository there is a `setup.sh` script which does the following:

* initialize the git submodules which point to the Unikraft catalogs
* runs the `setup.sh script from the `catalog-core` submodule

## Examples

For now there are only Unikraft examples, more will be added in time, for instance examples based on `MirageOS`.

### Unikraft examples

#### catalog-core-c-hello

This example is based on the [`C Hello on Unikraft](https://github.com/unikraft/catalog-core/tree/scripts/c-hello) from the catalog-core.

#### catalog-nginx-1.25

This example is based on the [Nginx 1.25](https://github.com/unikraft/catalog/tree/main/library/nginx/1.25).


