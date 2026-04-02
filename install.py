#!/usr/bin/env python3
"""Dotfiles installer.

Goals:
- Keep the config selection model (e.g. "omarchy").
- Allow each module to declare its own input + output locations.
- Stay easy to extend: add a module in one place, then include it in a config.

The installer supports two module types:
- StowModule: installs via GNU Stow (symlinks a package directory)
- LinkFileModule: symlinks a single file into a target directory
"""

from __future__ import annotations

import argparse
import os
import shutil
import stat
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, NoReturn


def eprint(msg: str) -> None:
    print(msg, file=sys.stderr)


def die(msg: str, code: int = 1) -> "NoReturn":
    eprint(f"Error: {msg}")
    raise SystemExit(code)


def repo_root() -> Path:
    # Assumes this script lives at the repository root.
    return Path(__file__).resolve().parent


def expand_path(value: str) -> Path:
    return Path(os.path.expandvars(os.path.expanduser(value))).resolve()


@dataclass(frozen=True)
class StowModule:
    """A stow package to install.

    stow_dir: directory passed to `stow --dir` (relative to repo root)
    package:  package name (a directory inside stow_dir)
    target:   path passed to `stow --target`
    """

    id: str
    stow_dir: str
    package: str
    target: str


@dataclass(frozen=True)
class LinkFileModule:
    """Symlink a single file into a target directory."""

    id: str
    source: str  # path relative to repo root
    target_dir: str
    target_name: str | None = None
    require_executable: bool = False


Module = StowModule | LinkFileModule


def build_registry() -> dict[str, Module]:
    """All available modules.

    Extend by adding a new entry here, then adding its id to a config in
    `build_configs()`.
    """

    return {
        # Packages mirror the target tree under $HOME (stow target is ~).
        "themes": StowModule(
            id="themes",
            stow_dir=".",
            package="themes",
            target="~",
        ),
        "waybar": StowModule(
            id="waybar",
            stow_dir=".",
            package="waybar",
            target="~",
        ),
        "hypr": StowModule(
            id="hypr",
            stow_dir=".",
            package="hypr",
            target="~",
        ),
        "OpenTabletDriver": StowModule(
            id="OpenTabletDriver",
            stow_dir=".",
            package="OpenTabletDriver",
            target="~",
        ),
        "sublime-text": StowModule(
            id="sublime-text",
            stow_dir=".",
            package="sublime-text",
            target="~",
        ),
        "agents": StowModule(
            id="agents",
            stow_dir=".",
            package="agents",
            target="~/.agents",
        ),
        "omarchy": StowModule(
            id="omarchy",
            stow_dir=".",
            package="omarchy",
            target="~",
        ),
        "bin": StowModule(
            id="bin",
            stow_dir=".",
            package="bin",
            target="~",
        ),
        "systemd": StowModule(
            id="systemd",
            stow_dir=".",
            package="systemd",
            target="~",
        ),
    }


def build_configs() -> dict[str, list[str]]:
    """Config -> ordered module ids."""

    return {
        # Cross-platform/common modules.
        "global": [
            "themes",
            "waybar",
            "OpenTabletDriver",
            "bin",
            "sublime-text",
            "agents",
            "systemd",
        ],
        # Full Hyprland desktop (includes Omarchy theme for now).
        "desktop": [
            "themes",
            "waybar",
            "hypr",
            "OpenTabletDriver",
            "bin",
            "sublime-text",
            "agents",
            "systemd",
            "omarchy",
        ],
        # Legacy alias for "desktop" config.
        "omarchy": [
            "waybar",
            "hypr",
            "OpenTabletDriver",
            "bin",
            "sublime-text",
            "agents",
            "systemd",
            "omarchy",
        ],
    }


def parse_args(argv: list[str]) -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Install dotfiles modules.")
    p.add_argument("config", nargs="?", help="Configuration name (e.g. omarchy)")
    p.add_argument(
        "--list",
        action="store_true",
        help="List configs and modules, then exit",
    )
    p.add_argument(
        "--dry-run",
        action="store_true",
        help="Print what would happen, but do not run commands",
    )
    p.add_argument(
        "--verbose",
        action="store_true",
        help="Print commands and extra details",
    )
    p.add_argument(
        "--only",
        action="append",
        default=[],
        metavar="MODULE_ID",
        help="Install only these modules (repeatable); ignores config",
    )
    p.add_argument(
        "--restow",
        action="store_true",
        help="Pass --restow to stow (useful after reorganizing files)",
    )
    p.add_argument(
        "--fix-perms",
        action="store_true",
        help="If a LinkFileModule requires +x, chmod the source file in-repo",
    )
    return p.parse_args(argv)


def ordered_unique(items: Iterable[str]) -> list[str]:
    seen: set[str] = set()
    out: list[str] = []
    for x in items:
        if x in seen:
            continue
        seen.add(x)
        out.append(x)
    return out


def ensure_stow_available() -> None:
    if shutil.which("stow") is None:
        die("GNU Stow is not installed. Please install it before running this script.")


def validate_module_id(registry: dict[str, Module], module_id: str) -> None:
    if module_id not in registry:
        known = ", ".join(sorted(registry.keys()))
        die(f"Unknown module '{module_id}'. Known: {known}")


def module_needs_stow(m: Module) -> bool:
    return isinstance(m, StowModule)


def install_stow_module(
    root: Path,
    m: StowModule,
    *,
    dry_run: bool,
    verbose: bool,
    restow: bool,
) -> None:
    src = root / m.stow_dir / m.package
    if not src.is_dir():
        die(f"Directory '{src}' does not exist")

    target = expand_path(m.target)
    target.mkdir(parents=True, exist_ok=True)

    cmd = ["stow", "--dir", m.stow_dir, "--target", str(target), "-v"]
    if restow:
        cmd.append("--restow")
    cmd.append(m.package)

    print(f"\u2192 Stowing {m.stow_dir}/{m.package} -> {target}")
    if verbose:
        print("  " + " ".join(cmd))

    if dry_run:
        return

    subprocess.run(cmd, cwd=root, check=True)


def is_executable(path: Path) -> bool:
    try:
        mode = path.stat().st_mode
    except OSError:
        return False
    return bool(mode & (stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH))


def chmod_add_user_exec(path: Path) -> None:
    st = path.stat()
    path.chmod(st.st_mode | stat.S_IXUSR)


def install_link_file_module(
    root: Path,
    m: LinkFileModule,
    *,
    dry_run: bool,
    verbose: bool,
    fix_perms: bool,
) -> None:
    src = (root / m.source).resolve()
    if not src.is_file():
        die(f"File '{src}' does not exist")

    if m.require_executable and not is_executable(src):
        if fix_perms:
            if verbose:
                print(f"  chmod +x {src}")
            if not dry_run:
                chmod_add_user_exec(src)
        else:
            die(
                f"'{m.source}' is not executable. Run: chmod +x {m.source} "
                "(or re-run with --fix-perms)"
            )

    target_dir = expand_path(m.target_dir)
    target_dir.mkdir(parents=True, exist_ok=True)
    target_name = m.target_name if m.target_name is not None else src.name
    intended_dst = target_dir / target_name

    print(f"\u2192 Linking {m.source} -> {intended_dst}")
    if verbose:
        print(f"  ln -s {src} {intended_dst}")

    if dry_run:
        return

    # Idempotency: if the destination is already the correct symlink, do nothing.
    if intended_dst.is_symlink():
        current = intended_dst.resolve()
        if current == src:
            return
        die(f"Refusing to replace existing symlink '{intended_dst}' -> '{current}'")

    if intended_dst.exists():
        die(f"Refusing to overwrite existing path '{intended_dst}'")

    intended_dst.symlink_to(src)


def list_things(registry: dict[str, Module], configs: dict[str, list[str]]) -> int:
    print("Configs:")
    for name in sorted(configs.keys()):
        print(f"  {name}")

    print("\nModules:")
    for mid in sorted(registry.keys()):
        m = registry[mid]
        if isinstance(m, StowModule):
            print(f"  {m.id}: stow {m.stow_dir}/{m.package} -> {m.target}")
        else:
            tn = m.target_name if m.target_name is not None else Path(m.source).name
            print(f"  {m.id}: link {m.source} -> {m.target_dir}/{tn}")

    return 0


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    root = repo_root()

    registry = build_registry()
    configs = build_configs()

    if args.list:
        return list_things(registry, configs)

    if args.only:
        selected_ids = ordered_unique(args.only)
    else:
        if not args.config:
            die("Usage: ./install.py <config>")
        config = args.config.lower()
        if config not in configs:
            valid = ", ".join(sorted(configs.keys()))
            die(f"Unknown configuration '{args.config}'. Valid options: {valid}")
        selected_ids = configs[config]
        print(f"Installing configuration: {config}\n")

    for mid in selected_ids:
        validate_module_id(registry, mid)

    # Only require stow if we actually selected a stow-based module.
    if any(module_needs_stow(registry[mid]) for mid in selected_ids):
        ensure_stow_available()

    for mid in selected_ids:
        m = registry[mid]
        if isinstance(m, StowModule):
            install_stow_module(
                root,
                m,
                dry_run=args.dry_run,
                verbose=args.verbose,
                restow=args.restow,
            )
        else:
            install_link_file_module(
                root,
                m,
                dry_run=args.dry_run,
                verbose=args.verbose,
                fix_perms=args.fix_perms,
            )

    print("\nDone.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
