#!/usr/bin/env bash
set -euo pipefail

LAB="enterprise-skeleton"
RENDER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/rendered"

NODES=(SP-P1 HQ-EDGE BR1 BR2 BR3)

for n in "${NODES[@]}"; do
  c="clab-${LAB}-${n}"
  src="${RENDER_DIR}/${n}"

  echo "==> Deploying FRR config to ${n} (${c})"
  test -f "${src}/frr.conf"
  test -f "${src}/daemons"

  docker cp "${src}/frr.conf"  "${c}:/etc/frr/frr.conf"
  docker cp "${src}/daemons"  "${c}:/etc/frr/daemons"

  docker exec -it "${c}" bash -lc '
    set -e
    mkdir -p /var/run/frr
    touch /etc/frr/vtysh.conf
    chown -R frr:frr /etc/frr /var/run/frr || true
    chmod 640 /etc/frr/frr.conf /etc/frr/daemons /etc/frr/vtysh.conf || true

    # Restart ospfd cleanly (zebra/watchfrr are already running in this image)
    pkill -x ospfd 2>/dev/null || true
    sleep 1
    /usr/lib/frr/ospfd -d -F traditional -A 127.0.0.1 -f /etc/frr/frr.conf -u frr -g frr || true

    vtysh -c "show ip ospf neighbor" >/dev/null 2>&1 || true
  '

done

echo "✅ FRR OSPF deploy complete"
