#!/usr/bin/env bash

# Packs the modules CI built for one kernel into dxgdrm-<release>.tar.gz, in
# the layout of the flake's package: lib/modules/<release>/extra/*.ko with a
# modules.dep, so `modprobe -d <dir> dxgdrm` loads the DRM core modules first,
# plus the udev rules. Unpack it into any directory and point modprobe -d at it.
#
# Usage: release-tarball.sh <artifact dir> <kernel release> <output dir>

set -euo pipefail

ARTIFACT="$1"
RELEASE="$2"
OUT="$3"

STAGE="$(mktemp -d)"
trap 'rm -rf "${STAGE}"' EXIT

EXTRA="${STAGE}/lib/modules/${RELEASE}/extra"
mkdir -p "${EXTRA}" "${OUT}"
find "${ARTIFACT}" -name '*.ko' -exec install -m644 -t "${EXTRA}" {} +
# The debug info is most of the size, and modprobe does not need it.
for KO in "${EXTRA}"/*.ko; do
    objcopy --strip-debug "${KO}"
done
depmod -b "${STAGE}" "${RELEASE}"
install -Dm644 "$(dirname "$0")/99-dxgdrm.rules" "${STAGE}/lib/udev/rules.d/99-dxgdrm.rules"

tar -C "${STAGE}" --owner=0 --group=0 -czf "${OUT}/dxgdrm-${RELEASE}.tar.gz" lib
