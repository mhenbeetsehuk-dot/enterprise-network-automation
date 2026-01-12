#!/usr/bin/env python3
from pathlib import Path
import yaml
from jinja2 import Environment, FileSystemLoader

DATA_FILE = "data/routing/bgp.yml"
TEMPLATE_DIR = "templates"
TEMPLATE_FILE = "bgp_snip.j2"
OUT_DIR = Path("rendered/bgp")

def main():
    data = yaml.safe_load(open(DATA_FILE))
    nodes = data["bgp"]["nodes"]

    env = Environment(loader=FileSystemLoader(TEMPLATE_DIR), trim_blocks=True, lstrip_blocks=True)
    tmpl = env.get_template(TEMPLATE_FILE)

    OUT_DIR.mkdir(parents=True, exist_ok=True)

    for name, cfg in nodes.items():
        text = tmpl.render(node=cfg)
        out = OUT_DIR / f"{name}_bgp.snip"
        out.write_text(text)
        print(f"Wrote {out}")

if __name__ == "__main__":
    main()
