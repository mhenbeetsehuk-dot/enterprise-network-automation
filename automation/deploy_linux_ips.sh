#!/usr/bin/env bash
set -euo pipefail

NODES=("SP-P1" "HQ-EDGE" "BR1")

for n in "${NODES[@]}"; do
  c="${n}"
  echo "==> Applying Linux IPs on $c"

  docker cp "automation/rendered/${n}/linux_ifaces.sh" "${c}:/tmp/linux_ifaces.sh"
  docker exec "${c}" bash -lc "bash /tmp/linux_ifaces.sh"

  echo "==> $c (links):"
  docker exec "${c}" bash -lc "ip -br link | grep -E '^(eth|lo)'"
  echo "==> $c (addresses):"
  docker exec "${c}" bash -lc "ip -br addr | grep -E '^(eth|lo)'"
done

echo "✅ Linux IP configuration applied."
