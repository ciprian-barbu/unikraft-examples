#!/bin/bash

docker run -m 256M --runtime "io.containerd.urunc.v2" --rm -it --name c-hello catalog-core-c-hello:latest
