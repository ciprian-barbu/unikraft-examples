#!/bin/bash

git submodule update --init
(cd unikraft/catalog-core; ./setup.sh)
