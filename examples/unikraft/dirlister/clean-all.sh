#!/bin/bash

rm -rf .unikraft .config.dirlister_qemu-x86_64
# Remove the Docker image
# Remove the Docker image
docker rmi dirlister-rootfs:latest || true
docker rmi dirlister:latest || true
