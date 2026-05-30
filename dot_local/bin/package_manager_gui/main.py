#!/usr/bin/python3
"""PyQt6 GUI package manager for dotfiles.

A graphical interface for managing packages in a dotfiles repository,
allowing users to persist, ignore, or filter packages by OS and device.

Usage:
    python -m package_manager_gui
"""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Optional

from PyQt6.QtCore import Qt, QModelIndex
from PyQt6.QtGui import QColor
from PyQt6.QtWidgets import (
    QApplication,
    QMainWindow,
    QWidget,
    QVBoxLayout,
    QHBoxLayout,
    QLabel,
    QComboBox,
    QPushButton,
    QTableWidget,
    QTableWidgetItem,
    QSplitter,
    QMessageBox,
    QAbstractItemView,
    QItemDelegate,
    QStyledItemDelegate,
)

from .manager import PackageManager
from .models import Package
from .constants import PACKAGES_YAML, STATE_JSON


class PackageDelegate(QStyledItemDelegate):
    """Custom delegate for editing package OS and Device in tables.
    
    Provides dropdown editors for OS and Device columns, and prevents
    editing of the Name column.
    """
    
    def __init__(self, parent: QWidget | None = None) -> None:
        """Initialize the delegate."""
        super().__init__(parent)
        self.os_choices = ["all", "omarchy"]
        self.device_choices = ["all", "desktop", "laptop"]
    
    def createEditor(
        self, parent: QWidget, option, index: QModelIndex
    ) -> QWidget | None:
        """Create an editor widget for the given index.
        
        Args:
            parent: Parent widget
            option: Style options
            index: Model index being edited
            
        Returns:
            QComboBox for columns 1 (OS) or 2 (Device), None for other columns.
        """
        column = index.column()
        
        # Column 0 (Name) is read-only
        if column == 0:
            return None
        
        # Column 1 (OS) - show OS dropdown
        if column == 1:
            editor = QComboBox(parent)
            editor.addItems(self.os_choices)
            return editor
        
        # Column 2 (Device) - show Device dropdown
        if column == 2:
            editor = QComboBox(parent)
            editor.addItems(self.device_choices)
            return editor
        
        return None
    
    def setEditorData(self, editor: QWidget, index: QModelIndex) -> None:
        """Set the current value in the editor.
        
        Args:
            editor: Editor widget (QComboBox)
            index: Model index being edited
        """
        if not isinstance(editor, QComboBox):
            return
        
        # Get the current value from the table item
        current_value = index.model().data(index, Qt.ItemDataRole.DisplayRole)
        if current_value:
            editor.setCurrentText(current_value)
    
    def setModelData(
        self, editor: QWidget, model, index: QModelIndex
    ) -> None:
        """Update the model with the editor value.
        
        Args:
            editor: Editor widget (QComboBox)
            model: Model (not used, we update via table)
            index: Model index being edited
        """
        if not isinstance(editor, QComboBox):
            return
        
        new_value = editor.currentText()
        
        # Update the table item
        table_widget = self.parent()
        if not isinstance(table_widget, QTableWidget):
            return
        
        item = table_widget.item(index.row(), index.column())
        if not item:
            return
        
        # Get the package from the Name column (column 0)
        pkg_item = table_widget.item(index.row(), 0)
        if not pkg_item:
            return
        
        pkg = pkg_item.data(Qt.ItemDataRole.UserRole)
        if not pkg:
            return
        
        # Update the package data
        column = index.column()
        if column == 1:  # OS column
            pkg.os = new_value
        elif column == 2:  # Device column
            pkg.device = new_value
        
        # Update the cell display
        item.setText(new_value)
        
        # Mark the entire row with yellow background to indicate modification
        bg_color = QColor(255, 250, 205)  # Light yellow
        for col in range(table_widget.columnCount()):
            table_widget.item(index.row(), col).setBackground(bg_color)


class PackageManagerWindow(QMainWindow):
    """Main window for the package manager application.
    
    Provides a GUI for managing persisted and pending packages
    with filtering by OS and device.
    """

    def __init__(self) -> None:
        """Initialize the main window."""
        super().__init__()
        self.setWindowTitle("Package Manager")
        self.setGeometry(100, 100, 1200, 800)
        
        # Initialize package manager
        self.manager = PackageManager(PACKAGES_YAML, STATE_JSON)
        try:
            self.manager.load()
        except Exception as e:
            QMessageBox.critical(
                self,
                "Error Loading Packages",
                f"Failed to load packages: {e}"
            )
            sys.exit(1)
        
        # State variables
        self._current_os_filter = "all"
        self._current_device_filter = "all"
        self._showing_pending = True  # Toggle between pending/ignored
        self._editing_package: Optional[Package] = None  # Package being edited (hover mode)
        
        # Track original state for visual indicators (show which packages have been moved)
        self._original_state: dict[tuple[str, str], str] = {}  # (name, source) -> original state
        self._store_original_state()
        
        # Create UI
        self._create_ui()
        self._load_packages()
    
    def _create_ui(self) -> None:
        """Create the user interface."""
        # Create central widget
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        
        main_layout = QVBoxLayout()
        central_widget.setLayout(main_layout)
        
        # Top filter bar
        filter_layout = QHBoxLayout()
        
        # OS filter dropdown
        filter_layout.addWidget(QLabel("OS:"))
        self.os_combo = QComboBox()
        self.os_combo.addItems(["all", "omarchy"])
        self.os_combo.setCurrentText("all")
        self.os_combo.currentTextChanged.connect(self._on_os_filter_changed)
        filter_layout.addWidget(self.os_combo)
        
        # Device filter dropdown
        filter_layout.addWidget(QLabel("Device:"))
        self.device_combo = QComboBox()
        self.device_combo.addItems(["all", "desktop", "laptop"])
        self.device_combo.setCurrentText("all")
        self.device_combo.currentTextChanged.connect(self._on_device_filter_changed)
        filter_layout.addWidget(self.device_combo)
        
        # Toggle button for pending/ignored view
        filter_layout.addStretch()
        self.toggle_view_btn = QPushButton("Show Ignored")
        self.toggle_view_btn.clicked.connect(self._on_toggle_view)
        filter_layout.addWidget(self.toggle_view_btn)
        
        main_layout.addLayout(filter_layout)
        
        # Main content area with splitter
        splitter = QSplitter(Qt.Orientation.Horizontal)
        
        # Left column: Persisted packages
        left_widget = QWidget()
        left_layout = QVBoxLayout()
        left_layout.addWidget(QLabel("Persisted Packages"))
        self.left_table = QTableWidget()
        self.left_table.setColumnCount(3)
        self.left_table.setHorizontalHeaderLabels(["Name", "OS", "Device"])
        self.left_table.setSelectionMode(QAbstractItemView.SelectionMode.SingleSelection)
        self.left_table.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)
        self.left_table.setEditTriggers(QAbstractItemView.EditTrigger.DoubleClicked)
        self.left_table.doubleClicked.connect(self._on_left_table_double_click)
        self.left_table.horizontalHeader().setStretchLastSection(False)
        
        # Set custom delegate for inline editing
        self.left_delegate = PackageDelegate(self.left_table)
        self.left_table.setItemDelegate(self.left_delegate)
        
        left_layout.addWidget(self.left_table)
        left_widget.setLayout(left_layout)
        
        # Right column: Pending or Ignored packages
        right_widget = QWidget()
        right_layout = QVBoxLayout()
        self.right_title = QLabel("Pending Packages")
        right_layout.addWidget(self.right_title)
        self.right_table = QTableWidget()
        self.right_table.setColumnCount(2)
        self.right_table.setHorizontalHeaderLabels(["Name", "Source"])
        self.right_table.setSelectionMode(QAbstractItemView.SelectionMode.SingleSelection)
        self.right_table.setSelectionBehavior(QAbstractItemView.SelectionBehavior.SelectRows)
        self.right_table.doubleClicked.connect(self._on_right_table_double_click)
        self.right_table.horizontalHeader().setStretchLastSection(False)
        right_layout.addWidget(self.right_table)
        right_widget.setLayout(right_layout)
        
        # Add columns to splitter
        splitter.addWidget(left_widget)
        splitter.addWidget(right_widget)
        splitter.setStretchFactor(0, 1)
        splitter.setStretchFactor(1, 1)
        
        main_layout.addWidget(splitter, 1)
        
        # Bottom buttons
        button_layout = QHBoxLayout()
        button_layout.addStretch()
        
        self.save_btn = QPushButton("Save")
        self.save_btn.clicked.connect(self._on_save)
        button_layout.addWidget(self.save_btn)
        
        self.cancel_btn = QPushButton("Cancel")
        self.cancel_btn.clicked.connect(self._on_cancel)
        button_layout.addWidget(self.cancel_btn)
        
        main_layout.addLayout(button_layout)
    
    def _load_packages(self) -> None:
        """Load and display packages from manager."""
        self._update_left_column()
        self._update_right_column()
    
    def _store_original_state(self) -> None:
        """Store the original state of all packages for moved package tracking.
        
        Maps each (name, source) tuple to its original state: persisted, pending, or ignored.
        """
        # Track persisted packages
        for pkg in self.manager.state.persisted_packages:
            key = (pkg.name, pkg.source)
            self._original_state[key] = "persisted"
        
        # Track pending packages
        for pkg in self.manager.state.pending_packages:
            key = (pkg.name, pkg.source)
            self._original_state[key] = "pending"
        
        # Track ignored packages
        for pkg in self.manager.state.ignored_packages:
            key = (pkg.name, pkg.source)
            self._original_state[key] = "ignored"
    
    def _is_package_moved(self, pkg: Package, current_state: str) -> bool:
        """Check if a package has been moved from its original state.
        
        Args:
            pkg: Package to check
            current_state: Current state (persisted, pending, or ignored)
            
        Returns:
            True if package was moved from its original state, False otherwise.
        """
        key = (pkg.name, pkg.source)
        original = self._original_state.get(key)
        return original is not None and original != current_state
    
    def _get_moved_background_color(self) -> QColor:
        """Get the background color for moved packages.
        
        Returns:
            QColor object for light yellow/orange background.
        """
        from PyQt6.QtGui import QColor
        return QColor(255, 250, 205)  # Light yellow (LemonChiffon)
    
    def _update_left_column(self) -> None:
        """Update the left column (persisted packages) based on current filters."""
        self.left_table.setRowCount(0)
        
        persisted = self.manager.get_persisted_filtered(
            device=self._current_device_filter,
            os=self._current_os_filter
        )
        
        for pkg in persisted:
            row = self.left_table.rowCount()
            self.left_table.insertRow(row)
            
            # Column 1: Package name with [aur] badge
            name_text = pkg.name
            if pkg.source == "aur":
                name_text = f"{name_text} [aur]"
            name_item = QTableWidgetItem(name_text)
            name_item.setData(Qt.ItemDataRole.UserRole, pkg)
            
            # Column 2: OS
            os_item = QTableWidgetItem(pkg.os)
            
            # Column 3: Device
            device_item = QTableWidgetItem(pkg.device)
            
            # Set items in row
            self.left_table.setItem(row, 0, name_item)
            self.left_table.setItem(row, 1, os_item)
            self.left_table.setItem(row, 2, device_item)
            
            # Apply background color if package was moved from another state
            if self._is_package_moved(pkg, "persisted"):
                bg_color = self._get_moved_background_color()
                for col in range(3):
                    self.left_table.item(row, col).setBackground(bg_color)
        
        # Resize columns to content
        self.left_table.resizeColumnsToContents()
    
    def _update_right_column(self) -> None:
        """Update the right column (pending or ignored packages)."""
        self.right_table.setRowCount(0)
        
        if self._showing_pending:
            packages = self.manager.get_pending_packages()
            self.right_title.setText("Pending Packages")
            self.toggle_view_btn.setText("Show Ignored")
            current_state = "pending"
        else:
            packages = self.manager.get_ignored()
            self.right_title.setText("Ignored Packages")
            self.toggle_view_btn.setText("Show Pending")
            current_state = "ignored"
        
        for pkg in packages:
            row = self.right_table.rowCount()
            self.right_table.insertRow(row)
            
            # Column 1: Package name with [aur] badge
            name_text = pkg.name
            if pkg.source == "aur":
                name_text = f"{name_text} [aur]"
            name_item = QTableWidgetItem(name_text)
            name_item.setData(Qt.ItemDataRole.UserRole, pkg)
            
            # Column 2: Source
            source_item = QTableWidgetItem(pkg.source)
            
            # Set items in row
            self.right_table.setItem(row, 0, name_item)
            self.right_table.setItem(row, 1, source_item)
            
            # Apply background color if package was moved from another state
            if self._is_package_moved(pkg, current_state):
                bg_color = self._get_moved_background_color()
                for col in range(2):
                    self.right_table.item(row, col).setBackground(bg_color)
        
        # Resize columns to content
        self.right_table.resizeColumnsToContents()
    
    def _on_os_filter_changed(self, value: str) -> None:
        """Handle OS filter change."""
        self._current_os_filter = value
        self._update_left_column()
    
    def _on_device_filter_changed(self, value: str) -> None:
        """Handle Device filter change."""
        self._current_device_filter = value
        self._update_left_column()
    
    def _on_toggle_view(self) -> None:
        """Toggle between pending and ignored view."""
        self._showing_pending = not self._showing_pending
        self._update_right_column()
    
    def _on_persisted_hover(self, item: QTableWidgetItem) -> None:
        """Handle hover over persisted table item to show edit options."""
        pkg = item.data(Qt.ItemDataRole.UserRole)
        if pkg and self._editing_package != pkg:
            self._editing_package = pkg
    
    def _on_persisted_leave(self, event) -> None:  # type: ignore
        """Handle leaving persisted table to clear edit mode."""
        self._editing_package = None
    
    def _on_left_table_double_click(self, index: QModelIndex) -> None:
        """Handle double-click on left table row.
        
        - Double-click on Name column (0): Move package to right column
        - Double-click on OS/Device columns (1/2): Edit the value via delegate
        """
        column = index.column()
        
        # Only move on Name column (column 0)
        # OS and Device columns will be handled by the delegate
        if column != 0:
            return
        
        # Get the package from the first column (which has the UserRole data)
        item = self.left_table.item(index.row(), 0)
        if not item:
            return
        
        pkg = item.data(Qt.ItemDataRole.UserRole)
        if not pkg:
            return
        
        # Move to pending or ignored based on current view
        target_state = "ignored" if not self._showing_pending else "pending"
        self.manager.move_package(pkg, target_state)
        self._load_packages()
    
    def _on_right_table_double_click(self, index: QModelIndex) -> None:
        """Handle double-click on right table row to move to left column."""
        # Get the package from the first column (which has the UserRole data)
        item = self.right_table.item(index.row(), 0)
        if not item:
            return
        
        pkg = item.data(Qt.ItemDataRole.UserRole)
        if not pkg:
            return
        
        # Move to persisted with current filter values
        self.manager.move_package(
            pkg,
            "persisted",
            device=self._current_device_filter,
            os=self._current_os_filter
        )
        self._load_packages()
    
    def _on_save(self) -> None:
        """Handle Save button click."""
        if not self.manager.has_unsaved_changes():
            QMessageBox.information(self, "No Changes", "No unsaved changes to save.")
            return
        
        try:
            self.manager.save()
            QMessageBox.information(self, "Success", "Packages saved successfully.")
            self.close()
        except Exception as e:
            QMessageBox.critical(self, "Save Error", f"Failed to save packages: {e}")
    
    def _on_cancel(self) -> None:
        """Handle Cancel button click."""
        if self.manager.has_unsaved_changes():
            result = QMessageBox.question(
                self,
                "Unsaved Changes",
                "You have unsaved changes. Save before closing?",
                QMessageBox.StandardButton.Save
                | QMessageBox.StandardButton.Discard
                | QMessageBox.StandardButton.Cancel
            )
            
            if result == QMessageBox.StandardButton.Save:
                self._on_save()
            elif result == QMessageBox.StandardButton.Discard:
                self.close()
            # Cancel does nothing (user stays in window)
        else:
            self.close()
    
    def closeEvent(self, event) -> None:  # type: ignore
        """Handle window close event (X button)."""
        if self.manager.has_unsaved_changes():
            result = QMessageBox.question(
                self,
                "Unsaved Changes",
                "You have unsaved changes. Save before closing?",
                QMessageBox.StandardButton.Save
                | QMessageBox.StandardButton.Discard
                | QMessageBox.StandardButton.Cancel
            )
            
            if result == QMessageBox.StandardButton.Save:
                try:
                    self.manager.save()
                    event.accept()
                except Exception as e:
                    QMessageBox.critical(self, "Save Error", f"Failed to save: {e}")
                    event.ignore()
            elif result == QMessageBox.StandardButton.Discard:
                event.accept()
            else:
                event.ignore()
        else:
            event.accept()


def main(argv: list[str] | None = None) -> int:
    """Application entry point.
    
    Args:
        argv: Command-line arguments (defaults to sys.argv if not provided).
        
    Returns:
        Application exit code.
    """
    if argv is None:
        argv = sys.argv
        
    try:
        app = QApplication(argv)
        window = PackageManagerWindow()
        window.show()
        return app.exec()
    except ImportError as e:
        print(f"Error: PyQt6 is required but not installed: {e}", file=sys.stderr)
        print("Install with: pacman -S python-pyqt6", file=sys.stderr)
        return 1
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
