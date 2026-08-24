"""High-level package manager orchestrating the data layer."""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

from .io import (
    load_packages_yaml,
    load_state_json,
    save_packages_yaml,
    save_state_json,
)
from .models import Package
from .state import PackageState


class PackageManager:
    """Orchestrates loading, managing, and persisting package state.
    
    Manages three conceptual states for packages:
    - Persisted: explicitly configured in packages.yaml
    - Pending: installed on system but not yet decided (needs user action)
    - Ignored: user has decided to ignore them
    """

    def __init__(self, packages_yaml_path: Path, state_json_path: Path) -> None:
        """Initialize the package manager with file paths.
        
        Args:
            packages_yaml_path: Path to packages.yaml
            state_json_path: Path to state.json
        """
        self.packages_yaml_path = packages_yaml_path
        self.state_json_path = state_json_path
        self.state = PackageState()
        self._unsaved_changes = False

    def load(self) -> None:
        """Load all package data from disk and calculate pending packages.
        
        This method:
        1. Loads persisted packages from packages.yaml
        2. Loads ignored package names from state.json
        3. Gets explicitly installed packages from pacman
        4. Calculates pending packages (installed but not persisted/ignored)
        5. Initializes the PackageState with all packages
        
        Raises:
            SystemExit: If required commands (pacman) are not available
            FileNotFoundError: If packages.yaml does not exist
        """
        # Load persisted packages from packages.yaml
        try:
            persisted = load_packages_yaml(self.packages_yaml_path)
        except FileNotFoundError as e:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)

        # Load ignored package names from state.json
        ignored_pacman_names, ignored_aur_names = load_state_json(self.state_json_path)

        # Get explicitly installed and AUR packages from system
        explicit = self._get_explicit_packages()
        aur = self._get_aur_packages()

        # Load omarchy packages and add to ignored sets
        omarchy_pacman, omarchy_aur = self._load_omarchy_packages()
        ignored_pacman_names.update(omarchy_pacman)
        ignored_aur_names.update(omarchy_aur)

        # Initialize state with persisted packages
        for pkg in persisted:
            self.state.persisted_packages.add(pkg)

        # Create ignored packages: only track those that are explicitly installed
        # This ensures pending packages don't include ignored packages
        persisted_pacman_names = {p.name for p in persisted if p.source == "pacman"}
        persisted_aur_names = {p.name for p in persisted if p.source == "aur"}

        for name in ignored_pacman_names:
            if name in explicit and name not in persisted_pacman_names:
                self.state.ignored_packages.add(Package(name=name, source="pacman"))

        for name in ignored_aur_names:
            if name in aur and name not in persisted_aur_names:
                self.state.ignored_packages.add(Package(name=name, source="aur"))

        # Calculate pending packages using the calculate_pending method
        # This ensures ignored packages are properly excluded from pending
        pending_packages = self.calculate_pending(
            explicit=explicit,
            aur=aur,
            ignored_pacman=ignored_pacman_names,
            ignored_aur=ignored_aur_names,
            persisted_pacman=persisted_pacman_names,
            persisted_aur=persisted_aur_names
        )
        self.state.pending_packages = pending_packages

        self._unsaved_changes = False

    def calculate_pending(
        self, explicit: set[str], aur: set[str], ignored_pacman: set[str], ignored_aur: set[str], persisted_pacman: set[str], persisted_aur: set[str]
    ) -> set[Package]:
        """Calculate pending packages by excluding persisted and ignored packages.
        
        Pending packages are those that are:
        - Explicitly installed on the system (in explicit or aur sets)
        - NOT in persisted packages
        - NOT in ignored packages
        
        Args:
            explicit: Set of explicitly installed pacman package names
            aur: Set of AUR (foreign) package names
            ignored_pacman: Set of ignored pacman package names
            ignored_aur: Set of ignored AUR package names
            persisted_pacman: Set of persisted pacman package names
            persisted_aur: Set of persisted AUR package names
            
        Returns:
            Set of Package objects that are pending (awaiting user decision).
        """
        pending: set[Package] = set()
        
        # Pending pacman: explicitly installed, not AUR, not persisted, not ignored
        pacman_only = explicit - aur
        pending_pacman_names = pacman_only - persisted_pacman - ignored_pacman
        for name in pending_pacman_names:
            pending.add(Package(name=name, source="pacman"))
        
        # Pending AUR: in aur, not persisted, not ignored
        pending_aur_names = aur - persisted_aur - ignored_aur
        for name in pending_aur_names:
            pending.add(Package(name=name, source="aur"))
        
        return pending

    def get_pending_packages(self) -> list[Package]:
        """Get all pending packages sorted by name.
        
        Returns:
            List of packages awaiting user decision.
        """
        return self.state.get_pending()

    def get_persisted_filtered(self, device: str = "all", os: str = "all") -> list[Package]:
        """Get persisted packages filtered by device and os.
        
        Args:
            device: Filter by device (all, desktop, laptop)
            os: Filter by os (all, omarchy)
            
        Returns:
            Filtered list of persisted packages sorted by name.
        """
        return self.state.get_persisted_filtered(device, os)

    def get_ignored(self) -> list[Package]:
        """Get all ignored packages sorted by name.
        
        Returns:
            List of ignored packages.
        """
        return self.state.get_ignored()

    def move_package(
        self,
        pkg: Package,
        target_state: str,
        device: str = "all",
        os: str = "all",
    ) -> None:
        """Move a package to a target state with optional metadata update.
        
        Args:
            pkg: Package to move
            target_state: Target state ('persisted', 'pending', or 'ignored')
            device: Device metadata for persisted packages (ignored for other states)
            os: OS metadata for persisted packages (ignored for other states)
            
        Raises:
            ValueError: If target_state is invalid.
        """
        if target_state == "persisted":
            self.state.move_to_persisted(pkg, device=device, os=os)
        elif target_state == "pending":
            self.state.move_to_pending(pkg)
        elif target_state == "ignored":
            self.state.move_to_ignored(pkg)
        else:
            raise ValueError(f"Invalid target state: {target_state}")

        self._unsaved_changes = True

    def save(self) -> None:
        """Save all changes to disk (atomically).
        
        Writes to both packages.yaml and state.json. If either write fails,
        raises an exception without partially updating the files.
        
        Raises:
            IOError: If writing to either file fails.
        """
        if not self._unsaved_changes:
            return

        try:
            # Save persisted packages
            save_packages_yaml(self.packages_yaml_path, self.state.persisted_packages)

            # Extract ignored package names by source
            ignored_pacman = {
                p.name for p in self.state.ignored_packages if p.source == "pacman"
            }
            ignored_aur = {
                p.name for p in self.state.ignored_packages if p.source == "aur"
            }

            # Save ignored packages state
            save_state_json(self.state_json_path, ignored_pacman, ignored_aur)

            self._unsaved_changes = False

        except Exception as e:
            print(f"Error saving package state: {e}", file=sys.stderr)
            raise

    def has_unsaved_changes(self) -> bool:
        """Check if there are unsaved changes.
        
        Returns:
            True if there are unsaved changes, False otherwise.
        """
        return self._unsaved_changes

    def _load_omarchy_packages(self) -> tuple[set[str], set[str]]:
        """Load omarchy packages and return them as ignored sets.
        
        Reads package names from:
        - $OMARCHY_PATH/install/omarchy-base.packages
        - $OMARCHY_PATH/install/omarchy-other.packages
        
        Returns:
            Tuple of (omarchy_pacman_names, omarchy_aur_names) where all packages
            are currently assumed to be pacman packages.
            
        Note:
            If files don't exist, returns empty sets silently.
        """
        omarchy_packages: set[str] = set()
        base_dir = Path(os.environ.get("OMARCHY_PATH", "/usr/share/omarchy")) / "install"
        
        for filename in ["omarchy-base.packages", "omarchy-other.packages"]:
            filepath = base_dir / filename
            if filepath.exists():
                try:
                    with open(filepath, "r") as f:
                        for line in f:
                            name = line.strip()
                            if name and not name.startswith("#"):  # Skip empty lines and comments
                                omarchy_packages.add(name)
                except Exception as e:
                    print(f"Warning: could not read {filepath}: {e}", file=sys.stderr)
        
        # All omarchy packages are pacman packages
        return omarchy_packages, set()

    @staticmethod
    def _run_cmd(cmd: list[str]) -> list[str]:
        """Run a shell command and return output lines.
        
        Args:
            cmd: Command to run
            
        Returns:
            List of output lines.
            
        Raises:
            subprocess.CalledProcessError: If command fails.
        """
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return [line.strip() for line in result.stdout.strip().split("\n") if line.strip()]

    @staticmethod
    def _get_explicit_packages() -> set[str]:
        """Get all explicitly installed packages (not dependencies).
        
        Returns:
            Set of package names.
            
        Raises:
            subprocess.CalledProcessError: If pacman command fails.
        """
        try:
            lines = PackageManager._run_cmd(["pacman", "-Qe"])
            return {line.split()[0] for line in lines}
        except (subprocess.CalledProcessError, FileNotFoundError, IndexError) as e:
            print(f"Warning: could not get explicit packages: {e}", file=sys.stderr)
            return set()

    @staticmethod
    def _get_aur_packages() -> set[str]:
        """Get all foreign (AUR) packages.
        
        Returns:
            Set of AUR package names.
            
        Raises:
            subprocess.CalledProcessError: If pacman command fails.
        """
        try:
            lines = PackageManager._run_cmd(["pacman", "-Qm"])
            return {line.split()[0] for line in lines}
        except (subprocess.CalledProcessError, FileNotFoundError, IndexError) as e:
            print(f"Warning: could not get AUR packages: {e}", file=sys.stderr)
            return set()
