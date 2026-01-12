#!/usr/bin/env bash
set -euo pipefail

NODE="${1:?Usage: bootstrap_frr.sh <container_name>}"

docker exec "$NODE" bash -lc '
set -e

mkdir -p /etc/frr /var/run/frr /var/log/frr
touch /etc/frr/vtysh.conf

# Ensure daemons file exists
if [ ! -f /etc/frr/daemons ]; then
  cat > /etc/frr/daemons <<DAEMONS
zebra=yes
bgpd=no
ospfd=yes
ospf6d=no
ripd=no
ripngd=no
isisd=no
pimd=no
ldpd=no
nhrpd=no
eigrpd=no
babeld=no
sharpd=no
pbrd=no
bfdd=no
fabricd=no
vrrpd=no
staticd=yes
DAEMONS
else
  sed -i "s/^zebra=.*/zebra=yes/" /etc/frr/daemons || true
  sed -i "s/^ospfd=.*/ospfd=yes/" /etc/frr/daemons || true
  sed -i "s/^staticd=.*/staticd=yes/" /etc/frr/daemons || true
fi

chown -R frr:frr /etc/frr /var/run/frr /var/log/frr || true
chmod 640 /etc/frr/daemons /etc/frr/vtysh.conf 2>/dev/null || true

/usr/lib/frr/frrinit.sh restart || /usr/lib/frr/frrinit.sh start || true
'
