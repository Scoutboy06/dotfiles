"""Path constants for the package manager."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


def get_chezmoi_source_path() -> Path:
    """Get chezmoi source directory path.
    
    Returns:
        Path to the chezmoi source directory.
        
    Raises:
        SystemExit: If chezmoi is not configured or source path cannot be retrieved.
    """
    try:
        result = subprocess.run(
            ["chezmoi", "source-path"],
            capture_output=True,
            text=True,
            check=True,
        )
        return Path(result.stdout.strip())
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        print(
            f"Error: could not get chezmoi source path: {e}",
            file=sys.stderr,
        )
        print("Make sure chezmoi is installed and configured.", file=sys.stderr)
        sys.exit(1)


# Chezmoi paths
CHEZMOI_SOURCE = get_chezmoi_source_path()
CHEZMOI_DATA = CHEZMOI_SOURCE / ".packages"

# Package data paths
PACKAGES_YAML = CHEZMOI_DATA / "packages.yaml"

# Application state paths
STATE_DIR = Path.home() / ".local" / "share" / "package-manager-gui"
STATE_JSON = STATE_DIR / "state.json"
