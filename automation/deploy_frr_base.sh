#!/usr/bin/env bash
set -euo pipefail

LAB="enterprise-skeleton"
NODES=("SP-P1" "HQ-EDGE" "BR1")

for n in "${NODES[@]}"; do
  c="clab-${LAB}-${n}"
  echo "==> Deploying to $c"

  docker cp "automation/rendered/${n}/daemons" "${c}:/etc/frr/daemons"
  docker cp "automation/rendered/${n}/frr.conf" "${c}:/etc/frr/frr.conf"

  docker exec "${c}" chown frr:frr /etc/frr/daemons /etc/frr/frr.conf
  docker exec "${c}" chmod 640 /etc/frr/daemons /etc/frr/frr.conf

  docker exec "${c}" bash -lc "service frr restart || /usr/lib/frr/frrinit.sh restart || true"
done

echo "✅ Base config deployed."
