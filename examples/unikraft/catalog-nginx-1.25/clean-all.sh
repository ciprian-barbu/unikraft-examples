#!/bin/bash

if ! test -d example-dir; then
  echo "Example-dir symlink not found, please run build.sh first"
  exit 1
fi

pushd example-dir
rm -rf .unikraft .config.nginx_qemu-x86_64
popd

rm nginx-qemu-x86_64 index.html

# Remove the Docker image
docker rmi catalog-nginx-1.25:latest
