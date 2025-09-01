#!/bin/bash

docker run -m 256M --runtime "io.containerd.urunc.v2" --rm -it --name dirlister dirlister:latest
