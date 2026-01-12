#!/bin/bash
set -euo pipefail

LAB_PREFIX="clab-enterprise-skeleton-"

for c in $(docker ps --format '{{.Names}}' | grep "${LAB_PREFIX}"); do
  node="${c#${LAB_PREFIX}}"

  snip="rendered/bgp/${node}_bgp.snip"
  if [[ ! -f "$snip" ]]; then
    echo "Missing $snip"
    exit 1
  fi

  echo "==> Updating BGP block on $node"

  # Remove old block (if present)
  docker exec "$c" sh -lc '
    if grep -q "! === BGP BEGIN ===" /etc/frr/frr.conf; then
      awk "
        BEGIN{skip=0}
        /! === BGP BEGIN ===/{skip=1; next}
        /! === BGP END ===/{skip=0; next}
        skip==0{print}
      " /etc/frr/frr.conf > /tmp/frr.conf && mv /tmp/frr.conf /etc/frr/frr.conf
    fi
  '

  # Copy snippet and append fresh block
  docker cp "$snip" "$c:/tmp/bgp.snip"
  docker exec "$c" sh -lc '
    {
      echo "! === BGP BEGIN ==="
      cat /tmp/bgp.snip
      echo "! === BGP END ==="
    } >> /etc/frr/frr.conf
  '

  # Permissions (BusyBox has chown/chmod)
  docker exec "$c" sh -lc 'chown frr:frr /etc/frr/frr.conf 2>/dev/null || true; chmod 640 /etc/frr/frr.conf 2>/dev/null || true'
done

echo "BGP blocks appended. Restart containers to reload FRR config."
