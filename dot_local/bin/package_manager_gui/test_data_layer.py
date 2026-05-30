#!/usr/bin/env python3
"""Test script for data layer imports and functionality."""

from __future__ import annotations

import sys
from pathlib import Path

# Add the bin directory to the path
sys.path.insert(0, str(Path(__file__).parent.parent))

# Test imports
print("Testing imports...")
try:
    from package_manager_gui.models import Package, VALID_SOURCES, VALID_DEVICES, VALID_OSS
    from package_manager_gui.state import PackageState
    from package_manager_gui.io import load_packages_yaml, save_packages_yaml
    from package_manager_gui.manager import PackageManager
    print("✓ All imports successful")
except ImportError as e:
    print(f"✗ Import failed: {e}")
    print(f"sys.path = {sys.path}")
    sys.exit(1)

# Test Package creation
print("\nTesting Package dataclass...")
pkg1 = Package(name="github-cli", source="pacman", device="all", os="all")
print(f"✓ Created package: {pkg1}")

pkg2 = Package(name="github-cli", source="pacman", device="desktop", os="all")
print(f"✓ Created second package: {pkg2}")

# Test equality (should be True - same name and source)
assert pkg1 == pkg2, "Package equality should be based on (name, source) only"
print("✓ Package equality works correctly (based on name, source)")

# Test hash consistency with equality
pkg_set = {pkg1}
assert pkg2 in pkg_set, "Package hash should match equality"
print("✓ Package hashing consistent with equality")

# Test __hash__
print(f"  hash(pkg1) = {hash(pkg1)}")
print(f"  hash(pkg2) = {hash(pkg2)}")

# Test invalid source
print("\nTesting Package validation...")
try:
    Package(name="test", source="invalid")
    print("✗ Should have raised ValueError for invalid source")
    sys.exit(1)
except ValueError as e:
    print(f"✓ Correctly rejected invalid source: {e}")

# Test PackageState
print("\nTesting PackageState...")
state = PackageState()
print("✓ Created PackageState")

state.move_to_persisted(pkg1, device="desktop", os="all")
assert len(state.persisted_packages) == 1
print("✓ moved package to persisted")

state.move_to_pending(pkg1)
assert len(state.persisted_packages) == 0
assert len(state.pending_packages) == 1
print("✓ moved package to pending")

state.move_to_ignored(pkg1)
assert len(state.pending_packages) == 0
assert len(state.ignored_packages) == 1
print("✓ moved package to ignored")

# Test filtering
print("\nTesting PackageState filtering...")
state = PackageState()

# Add packages with various device/os combinations
pkg_all = Package(name="pkg-all", source="pacman", device="all", os="all")
pkg_desktop = Package(name="pkg-desktop", source="pacman", device="desktop", os="all")
pkg_laptop = Package(name="pkg-laptop", source="pacman", device="laptop", os="all")

state.move_to_persisted(pkg_all, device="all", os="all")
state.move_to_persisted(pkg_desktop, device="desktop", os="all")
state.move_to_persisted(pkg_laptop, device="laptop", os="all")

# Filter by desktop
desktop_pkgs = state.get_persisted_filtered(device="desktop", os="all")
assert len(desktop_pkgs) == 2  # pkg_all (device="all" matches) and pkg_desktop
print(f"✓ Filtering for desktop: {[p.name for p in desktop_pkgs]}")

# Filter by laptop
laptop_pkgs = state.get_persisted_filtered(device="laptop", os="all")
assert len(laptop_pkgs) == 2  # pkg_all and pkg_laptop
print(f"✓ Filtering for laptop: {[p.name for p in laptop_pkgs]}")

# Filter all
all_pkgs = state.get_persisted_filtered(device="all", os="all")
assert len(all_pkgs) == 3
print(f"✓ Filtering for all: {[p.name for p in all_pkgs]}")

print("\n✓✓✓ All tests passed! ✓✓✓")
