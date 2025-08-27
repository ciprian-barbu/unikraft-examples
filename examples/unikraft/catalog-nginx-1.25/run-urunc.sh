#!/bin/bash

docker_img="catalog-nginx:1.25"
uk_name="nginx-1.25"

trap ctrl_c INT

function ctrl_c() {
  echo "Recived exit signal, removing container"
  docker rm -f ${uk_name}
  exit 0
}

docker run -m 256M --runtime "io.containerd.urunc.v2" --rm -id --name ${uk_name} ${docker_img}

ip_addr=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${uk_name})

running=$(docker inspect -f '{{.State.Status}}' ${uk_name})
echo "Runing status: ${running}"

if [ "${running}" != "running" ]; then
  echo "Unikernel not running"
  exit 1
fi

sleep 1

if ! wget "http://${ip_addr}/index.html" -O index.html; then
  echo "Failed to GET index.html"
  exit 1
fi

echo "Press Ctrl-C to stop the application"

read -r -d '' _ </dev/tty
