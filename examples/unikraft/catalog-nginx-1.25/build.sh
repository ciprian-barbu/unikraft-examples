#!/bin/bash

CDIR="$(readlink -f $(dirname ${BASH_SOURCE}))"
TOP_DIR="${CDIR}/../../.."
CATALOG="${TOP_DIR}/deps/unikraft/catalog"
EX_DIR="${CATALOG}/library/nginx/1.25"

if ! test -d "${CATALOG}"; then
  echo "Unikraft catalog not found. Please run the top-level setup.sh script first." 1>&2
  exit 1
fi

ln -s "${EX_DIR}" example-dir

pushd "${EX_DIR}"
kraft build --plat qemu --arch x86_64
popd

# For now copy the built binary because Docker buildx cannot access files from a location which is not downstream from current directory
cp "${EX_DIR}/.unikraft/build/nginx_qemu-x86_64" .
