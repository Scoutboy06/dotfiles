"""PyQt6 GUI package manager for dotfiles."""

from __future__ import annotations

from .manager import PackageManager
from .models import Package
from .state import PackageState

__version__ = "0.1.0"

__all__ = [
    "Package",
    "PackageState",
    "PackageManager",
]
