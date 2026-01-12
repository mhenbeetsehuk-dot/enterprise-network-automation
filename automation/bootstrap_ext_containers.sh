#!/usr/bin/env bash
set -euo pipefail

IMAGE="frrouting/frr:latest"
NODES=("SP-P1" "HQ-EDGE" "BR1")

for n in "${NODES[@]}"; do
  if docker ps -a --format '{{.Names}}' | grep -qx "${n}"; then
    echo "==> Removing existing ${n}"
    docker rm -f "${n}" >/dev/null || true
  fi

  echo "==> Creating ${n}"
  docker run -d --name "${n}" --hostname "${n}" \
    --privileged \
    --network none \
    "${IMAGE}" >/dev/null
done

echo "✅ External containers created: ${NODES[*]}"
