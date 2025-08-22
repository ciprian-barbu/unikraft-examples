#!/bin/bash

CDIR="$(readlink -f $(dirname ${BASH_SOURCE}))"
TOP_DIR="${CDIR}/../../.."
CATALOG_CORE="${TOP_DIR}/deps/unikraft/catalog-core"
EX_DIR="${CATALOG_CORE}/c-hello"

if ! test -d "${CATALOG_CORE}"; then
  echo "Unikraft catalog-core not found. Please run the top-level setup.sh script first." 1>&2
  exit 1
fi

ln -s "${EX_DIR}" example-dir

pushd "${EX_DIR}"
./setup.sh
./scripts/build/qemu.x86_64
popd

# For now copy the built binary because Docker buildx cannot access files from a location which is not downstream from current directory
cp "${EX_DIR}/workdir/build/c-hello_qemu-x86_64" .
