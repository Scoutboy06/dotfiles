"""State management for the package manager."""

from __future__ import annotations

from .models import Package


class PackageState:
    """Manages package state across three sets: persisted, pending, and ignored.
    
    Each package exists in exactly one set at a time. Moving a package from one
    set to another updates the metadata (device, os) as needed.
    """

    def __init__(self) -> None:
        """Initialize empty state."""
        self.persisted_packages: set[Package] = set()
        self.pending_packages: set[Package] = set()
        self.ignored_packages: set[Package] = set()

    def _find_package(self, pkg: Package) -> Package | None:
        """Find an existing package matching (name, source) in any set."""
        for existing in self.persisted_packages | self.pending_packages | self.ignored_packages:
            if existing == pkg:  # Equality is based on (name, source)
                return existing
        return None

    def _remove_from_all(self, pkg: Package) -> None:
        """Remove a package from all sets."""
        # Remove by (name, source) equality
        self.persisted_packages = {p for p in self.persisted_packages if p != pkg}
        self.pending_packages = {p for p in self.pending_packages if p != pkg}
        self.ignored_packages = {p for p in self.ignored_packages if p != pkg}

    def move_to_persisted(self, pkg: Package, device: str = "all", os: str = "all") -> None:
        """Move package to persisted set with updated metadata.
        
        Args:
            pkg: Package to move
            device: Device metadata (all, desktop, laptop)
            os: OS metadata (all, omarchy)
        """
        # Create new package with updated metadata
        updated_pkg = Package(name=pkg.name, source=pkg.source, device=device, os=os)
        self._remove_from_all(updated_pkg)
        self.persisted_packages.add(updated_pkg)

    def move_to_pending(self, pkg: Package) -> None:
        """Move package to pending set.
        
        Args:
            pkg: Package to move
        """
        self._remove_from_all(pkg)
        self.pending_packages.add(pkg)

    def move_to_ignored(self, pkg: Package) -> None:
        """Move package to ignored set.
        
        Args:
            pkg: Package to move
        """
        self._remove_from_all(pkg)
        self.ignored_packages.add(pkg)

    def get_persisted_filtered(self, device: str, os: str) -> list[Package]:
        """Get persisted packages filtered by device and os.
        
        Args:
            device: Filter by device (or "all" for all devices)
            os: Filter by os (or "all" for all os values)
            
        Returns:
            Filtered list of persisted packages, sorted by name.
        """
        filtered = [
            p for p in self.persisted_packages
            if (device == "all" or p.device == "all" or p.device == device)
            and (os == "all" or p.os == "all" or p.os == os)
        ]
        return sorted(filtered, key=lambda p: p.name)

    def get_pending(self) -> list[Package]:
        """Get all pending packages, sorted by name.
        
        Returns:
            List of pending packages sorted by name.
        """
        return sorted(self.pending_packages, key=lambda p: p.name)

    def get_ignored(self) -> list[Package]:
        """Get all ignored packages, sorted by name.
        
        Returns:
            List of ignored packages sorted by name.
        """
        return sorted(self.ignored_packages, key=lambda p: p.name)
