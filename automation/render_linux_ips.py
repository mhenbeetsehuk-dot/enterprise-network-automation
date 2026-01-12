#!/usr/bin/env python3
from pathlib import Path
import yaml

ROOT = Path(__file__).resolve().parents[1]

def load_yaml(p: Path):
    with p.open() as f:
        return yaml.safe_load(f)

def main():
    iface_db = load_yaml(ROOT / "data/topology/interfaces.yml")["interfaces"]
    out_root = ROOT / "automation" / "rendered"
    out_root.mkdir(parents=True, exist_ok=True)

    for node, ifaces in iface_db.items():
        node_dir = out_root / node
        node_dir.mkdir(parents=True, exist_ok=True)

        lines = [
            "#!/usr/bin/env bash",
            "set -euo pipefail",
            # bring all eth* up (safe)
            "for i in $(ls /sys/class/net | grep -E '^eth'); do ip link set $i up || true; done",
        ]
        for ifname, ipcidr in ifaces.items():
            lines += [
                f"ip addr flush dev {ifname} || true",
                f"ip addr add {ipcidr} dev {ifname}",
                f"ip link set {ifname} up",
            ]

        script = "\n".join(lines) + "\n"
        path = node_dir / "linux_ifaces.sh"
        path.write_text(script)
        path.chmod(0o755)

    print("✅ Rendered Linux IP scripts for:", ", ".join(sorted(iface_db.keys())))

if __name__ == "__main__":
    main()
