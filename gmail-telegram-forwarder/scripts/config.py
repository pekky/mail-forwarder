"""Config loader for Gmail -> Telegram forwarder.

Supports YAML (preferred) or JSON. Requires PyYAML for YAML.
"""
from __future__ import annotations

import json
from pathlib import Path


def load_config(path: str | Path) -> dict:
    path = Path(path)
    if not path.exists():
        raise FileNotFoundError(f"Config not found: {path}")

    if path.suffix.lower() in {".yaml", ".yml"}:
        try:
            import yaml  # type: ignore
        except Exception as exc:  # pragma: no cover
            raise RuntimeError(
                "PyYAML is required for YAML config. Install with 'pip install pyyaml'."
            ) from exc
        with path.open("r", encoding="utf-8") as f:
            return yaml.safe_load(f) or {}

    if path.suffix.lower() == ".json":
        with path.open("r", encoding="utf-8") as f:
            return json.load(f)

    raise ValueError("Config must be .yaml, .yml, or .json")
