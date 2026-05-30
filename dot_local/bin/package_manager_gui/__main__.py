"""Entry point for running the package manager as a module."""

from __future__ import annotations

import sys
from pathlib import Path

# Add the bin directory to the path to allow imports of package_manager_gui
sys.path.insert(0, str(Path(__file__).parent.parent))

from package_manager_gui.main import main

if __name__ == "__main__":
    sys.exit(main())
