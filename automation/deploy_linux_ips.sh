#!/usr/bin/env bash
set -euo pipefail

LAB_PREFIX="clab-enterprise-skeleton-"

for c in $(docker ps --format '{{.Names}}' | grep "^${LAB_PREFIX}"); do
  node="${c#${LAB_PREFIX}}"
  src="automation/rendered/${node}/linux_ifaces.sh"

  echo "==> Applying Linux IPs on $node ($c)"
  if [[ ! -f "$src" ]]; then
    echo "ERROR: Missing $src"
    exit 1
  fi

  docker cp "$src" "$c:/tmp/linux_ifaces.sh"
  docker exec "$c" sh -lc "chmod +x /tmp/linux_ifaces.sh && /tmp/linux_ifaces.sh"

  docker exec "$c" sh -lc "ip -br addr | grep -E '^(eth|lo)'"
done

echo "✅ Linux IP configuration applied."
