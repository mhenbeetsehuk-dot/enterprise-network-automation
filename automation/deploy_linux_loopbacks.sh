#!/bin/bash
set -euo pipefail

LAB_PREFIX="clab-enterprise-skeleton-"

declare -A LO
LO["SP-P1"]="1.1.1.1/32"
LO["HQ-EDGE"]="1.1.1.2/32"
LO["BR1"]="1.1.1.11/32"
LO["BR2"]="1.1.1.12/32"
LO["BR3"]="1.1.1.13/32"

echo "==> Applying loopbacks"
for c in $(docker ps --format '{{.Names}}' | grep "^${LAB_PREFIX}"); do
  node="${c#${LAB_PREFIX}}"
  ip="${LO[$node]:-}"

  if [[ -z "$ip" ]]; then
    echo "Skipping $node (no loopback defined)"
    continue
  fi

  echo "  - $node lo $ip"
  docker exec "$c" sh -lc "ip addr add $ip dev lo 2>/dev/null || true"
done
