"""Data models for the package manager."""

from __future__ import annotations

from dataclasses import dataclass


# Valid enum values for Package fields
VALID_SOURCES = {"pacman", "aur"}
VALID_DEVICES = {"all", "desktop", "laptop"}
VALID_OSS = {"all", "omarchy"}


@dataclass(frozen=False)
class Package:
    """Represents a managed package with metadata.
    
    Fields:
        name: Package name (e.g., 'github-cli')
        source: Package source (pacman or aur)
        device: Target device (all, desktop, or laptop)
        os: Target OS (all or omarchy)
    
    Equality is based on (name, source) only—device and os are metadata
    that can be modified independently.
    """

    name: str
    source: str
    device: str = "all"
    os: str = "all"

    def __post_init__(self) -> None:
        """Validate enum fields."""
        if self.source not in VALID_SOURCES:
            raise ValueError(f"Invalid source '{self.source}'. Must be one of {VALID_SOURCES}")
        if self.device not in VALID_DEVICES:
            raise ValueError(f"Invalid device '{self.device}'. Must be one of {VALID_DEVICES}")
        if self.os not in VALID_OSS:
            raise ValueError(f"Invalid os '{self.os}'. Must be one of {VALID_OSS}")

    def __hash__(self) -> int:
        """Hash based on (name, source) only for set membership."""
        return hash((self.name, self.source))

    def __eq__(self, other: object) -> bool:
        """Equality based on (name, source) only."""
        if not isinstance(other, Package):
            return NotImplemented
        return self.name == other.name and self.source == other.source

    def __repr__(self) -> str:
        """String representation for debugging."""
        return f"Package({self.name!r}, source={self.source}, device={self.device}, os={self.os})"
