"""I/O layer for persisting package data."""

from __future__ import annotations

import json
import sys
from pathlib import Path

from .models import Package

try:
    from ruamel.yaml import YAML
except ImportError:
    print("Error: python-ruamel-yaml is required", file=sys.stderr)
    print("Install with: sudo pacman -S python-ruamel-yaml", file=sys.stderr)
    sys.exit(1)


def load_packages_yaml(path: Path) -> set[Package]:
    """Load persisted packages from packages.yaml.
    
    Args:
        path: Path to packages.yaml
        
    Returns:
        Set of Package objects parsed from the YAML file.
        
    Raises:
        FileNotFoundError: If packages.yaml does not exist.
        ValueError: If YAML is malformed or packages lack required fields.
    """
    if not path.exists():
        raise FileNotFoundError(f"packages.yaml not found at {path}")

    try:
        yaml = YAML()
        data = yaml.load(path)

        packages: set[Package] = set()
        pkg_list = data.get("packages", []) if data else []

        for pkg_data in pkg_list:
            if not isinstance(pkg_data, dict):
                raise ValueError(f"Invalid package entry: {pkg_data}")

            name = pkg_data.get("name")
            source = pkg_data.get("source")
            device = pkg_data.get("device", "all")
            os = pkg_data.get("os", "all")

            if not name or not source:
                raise ValueError(f"Package missing required fields: {pkg_data}")

            packages.add(Package(name=name, source=source, device=device, os=os))

        return packages

    except Exception as e:
        raise ValueError(f"Failed to parse packages.yaml: {e}") from e


def save_packages_yaml(path: Path, packages: set[Package]) -> None:
    """Save persisted packages to packages.yaml, preserving YAML formatting.
    
    Args:
        path: Path to packages.yaml
        packages: Set of packages to save
        
    Note:
        Preserves existing YAML comments and formatting as much as possible
        by loading the file first and updating package entries in-place.
    """
    path.parent.mkdir(parents=True, exist_ok=True)

    # Load existing YAML to preserve comments and formatting
    yaml = YAML()
    yaml.preserve_quotes = True
    yaml.default_flow_style = False

    if path.exists():
        data = yaml.load(path)
    else:
        data = {"packages": []}

    # Convert packages to list of dicts
    new_pkg_list = [
        {
            "name": p.name,
            "source": p.source,
            "device": p.device,
            "os": p.os,
        }
        for p in sorted(packages, key=lambda p: p.name)
    ]

    # Update packages list
    data["packages"] = new_pkg_list

    # Write back to file
    with open(path, "w") as f:
        yaml.dump(data, f)


def load_state_json(path: Path) -> tuple[set[str], set[str]]:
    """Load ignored package names from state.json.
    
    Args:
        path: Path to state.json
        
    Returns:
        Tuple of (ignored_pacman_names, ignored_aur_names) as sets of package names.
        
    Note:
        If the file doesn't exist, returns empty sets.
    """
    if not path.exists():
        return set(), set()

    try:
        data = json.loads(path.read_text())
        ignored_pacman = set(data.get("ignored_pacman", []))
        ignored_aur = set(data.get("ignored_aur", []))
        return ignored_pacman, ignored_aur
    except (json.JSONDecodeError, TypeError) as e:
        raise ValueError(f"Failed to parse state.json: {e}") from e


def save_state_json(path: Path, ignored_pacman: set[str], ignored_aur: set[str]) -> None:
    """Save ignored package names to state.json.
    
    Args:
        path: Path to state.json
        ignored_pacman: Set of ignored pacman package names
        ignored_aur: Set of ignored AUR package names
    """
    path.parent.mkdir(parents=True, exist_ok=True)

    data = {
        "ignored_pacman": sorted(ignored_pacman),
        "ignored_aur": sorted(ignored_aur),
    }

    path.write_text(json.dumps(data, indent=2) + "\n")
