#!/usr/bin/env python3
from pathlib import Path
import yaml
from jinja2 import Environment, FileSystemLoader

ROOT = Path(__file__).resolve().parents[1]

def load_yaml(path: Path):
    with path.open() as f:
        return yaml.safe_load(f)

def main():
    iface_db = load_yaml(ROOT / "data/topology/interfaces.yml")["interfaces"]

    env = Environment(
        loader=FileSystemLoader(str(ROOT / "templates")),
        trim_blocks=True,
        lstrip_blocks=True,
    )

    frr_tpl = env.get_template("frr/frr.conf.j2")
    dae_tpl = env.get_template("frr/daemons.j2")

    out_root = ROOT / "automation" / "rendered"
    out_root.mkdir(parents=True, exist_ok=True)

    for hostname, ifaces in iface_db.items():
        node_dir = out_root / hostname
        node_dir.mkdir(parents=True, exist_ok=True)

        (node_dir / "frr.conf").write_text(
            frr_tpl.render(hostname=hostname, interfaces=ifaces) + "\n"
        )
        (node_dir / "daemons").write_text(dae_tpl.render() + "\n")

    print("✅ Rendered base configs for:", ", ".join(sorted(iface_db.keys())))

if __name__ == "__main__":
    main()
