#!/usr/bin/env bash
set -euo pipefail

NODES=("SP-P1" "HQ-EDGE" "BR1")

for n in "${NODES[@]}"; do
  echo "==> Deploying FRR config to $n"
  docker cp "automation/rendered/${n}/frr.conf" "${n}:/etc/frr/frr.conf"
  docker exec "${n}" bash -lc "chown frr:frr /etc/frr/frr.conf && chmod 640 /etc/frr/frr.conf"
done

for n in "${NODES[@]}"; do
  echo "==> Restarting FRR on $n"
  docker exec "${n}" bash -lc "/usr/lib/frr/frrinit.sh restart || /usr/lib/frr/frrinit.sh start"
done

echo "✅ FRR OSPF deploy complete."
