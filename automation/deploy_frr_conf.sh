#!/usr/bin/env bash
set -euo pipefail

NODES=("SP-P1" "HQ-EDGE" "BR1")

for n in "${NODES[@]}"; do
  echo "==> Deploying FRR config to ${n}"

  docker cp "automation/rendered/${n}/daemons" "${n}:/etc/frr/daemons"
  docker cp "automation/rendered/${n}/frr.conf" "${n}:/etc/frr/frr.conf"

  docker exec "${n}" chown frr:frr /etc/frr/daemons /etc/frr/frr.conf
  docker exec "${n}" chmod 640 /etc/frr/daemons /etc/frr/frr.conf

    docker exec "${n}" bash -lc '
set -e
# Best effort stop (ignore errors)
pkill -f "watchfrr|zebra|ospfd|bgpd|isisd" 2>/dev/null || true
sleep 1

# If frrinit exists, use it
if [ -x /usr/lib/frr/frrinit.sh ]; then
  /usr/lib/frr/frrinit.sh start || true
fi

# Ensure daemons are running (start manually if needed)
if ! pgrep -x zebra >/dev/null 2>&1; then
  zebra -d -A 127.0.0.1 -f /etc/frr/frr.conf || true
fi

if grep -q "^ospfd=yes" /etc/frr/daemons 2>/dev/null; then
  if ! pgrep -x ospfd >/dev/null 2>&1; then
    ospfd -d -A 127.0.0.1 -f /etc/frr/frr.conf || true
  fi
fi

# Quick status
ps -ef | egrep "zebra|ospfd|watchfrr" | grep -v egrep || true
'

done

echo "✅ FRR configs deployed and FRR restarted."
