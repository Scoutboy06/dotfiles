"""Run with /usr/bin/python3 -m unittest discover -s tests -p test_package_persist.py."""
import argparse
import importlib.machinery
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

SOURCE = Path(__file__).resolve().parents[1] / 'dot_local/bin/executable_package-persist'
loader = importlib.machinery.SourceFileLoader('package_persist', str(SOURCE))
spec = importlib.util.spec_from_loader(loader.name, loader)
app = importlib.util.module_from_spec(spec)
loader.exec_module(app)


class PackagePersistTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / '.packages').mkdir()
        for manager, name in [('pacman', 'fzf'), ('aur', 'brave-bin')]:
            (self.root / '.packages' / f'packages-{manager}.yaml').write_text(
                f'# Keep this header\npackages:\n- name: {name}\n  device: all\n  environment: dev\n')
        self.state = {'ignored_pacman': ['ignored-now-foreign'], 'ignored_aur': ['ignored-now-repo']}

    def test_inventory_uses_current_manifests_and_only_explicit_packages(self):
        def output(command):
            return {'-Qqe': 'fzf\nbrave-bin\nnew-repo\nnew-aur\nignored-now-foreign\nignored-now-repo',
                    '-Qqm': 'new-aur\ndependency\nignored-now-foreign'}[command[1]]
        with patch.object(app, 'output', side_effect=output):
            _, pending = app.inventory(self.root, self.state)
        self.assertEqual(pending, {'pacman': ['new-repo'], 'aur': ['new-aur']})

    def test_missing_manifest_fails_instead_of_reporting_everything(self):
        (self.root / '.packages/packages-aur.yaml').unlink()
        with self.assertRaises(FileNotFoundError):
            app.inventory(self.root, self.state)

    def test_persistence_preserves_schema_comments_and_deduplicates_across_sources(self):
        selected = {'pacman': ['new-repo', 'brave-bin'], 'aur': ['new-aur']}
        app.persist(self.root, selected, 'eliaspc', 'desktop')
        app.persist(self.root, selected, 'eliaspc', 'desktop')
        for manager, name in [('pacman', 'new-repo'), ('aur', 'new-aur')]:
            data = app.load_manifest(self.root, manager)
            self.assertEqual(len(data['packages']), 2)
            self.assertEqual(data['packages'][-1], {'name': name, 'device': 'eliaspc', 'environment': 'desktop'})
            self.assertTrue((self.root / '.packages' / f'packages-{manager}.yaml').read_text().startswith('# Keep this header'))
        self.assertFalse((self.root / '.chezmoidata').exists())

    def test_fzf_failure_does_not_save_decisions(self):
        result = subprocess.CompletedProcess([], 2, '', 'failure')
        with patch.object(app.subprocess, 'run', return_value=result), patch.object(app, 'atomic_write') as save:
            with self.assertRaises(RuntimeError):
                app.decide(argparse.Namespace(), self.root, self.state, {'pacman': ['new'], 'aur': []})
            save.assert_not_called()

    def test_empty_selection_requires_confirmation(self):
        result = subprocess.CompletedProcess([], 1, '', '')
        with patch.object(app.subprocess, 'run', return_value=result), patch('builtins.input', return_value='n'), patch.object(app, 'atomic_write') as save:
            app.decide(argparse.Namespace(), self.root, self.state, {'pacman': ['new'], 'aur': []})
            save.assert_not_called()

    def test_existing_ignore_state_is_preserved(self):
        path = self.root / 'state.json'
        app.atomic_write(path, '{"ignored_pacman": ["old"], "ignored_aur": [], "last_check": "yesterday"}')
        with patch.object(app, 'STATE_FILE', path):
            state = app.load_state()
        self.assertEqual(state['ignored_pacman'], ['old'])
        self.assertEqual(state['last_check'], 'yesterday')

    def test_empty_foreign_query_is_valid_but_database_errors_are_not(self):
        with patch.object(app.subprocess, 'run', return_value=subprocess.CompletedProcess([], 1, '', '')):
            self.assertEqual(app.output(['pacman', '-Qqm']), '')
        with patch.object(app.subprocess, 'run', return_value=subprocess.CompletedProcess([], 1, '', 'database error')):
            with self.assertRaises(subprocess.CalledProcessError):
                app.output(['pacman', '-Qqm'])

    def test_confirmed_selection_persists_and_preserves_previous_ignores(self):
        path = self.root / 'state.json'
        result = subprocess.CompletedProcess([], 0, '[pacman] new\n', '')
        args = argparse.Namespace(device='eliaspc', environment='dev')
        with patch.object(app, 'STATE_FILE', path), patch.object(app.subprocess, 'run', return_value=result), patch('builtins.input', return_value='y'):
            app.decide(args, self.root, self.state, {'pacman': ['new', 'skip'], 'aur': []})
            state = app.load_state()
        self.assertEqual(state['ignored_pacman'], ['ignored-now-foreign', 'skip'])
        self.assertEqual(app.load_manifest(self.root, 'pacman')['packages'][-1]['name'], 'new')

    def test_escape_does_not_save_anything(self):
        result = subprocess.CompletedProcess([], 130, '', '')
        with patch.object(app.subprocess, 'run', return_value=result), patch.object(app, 'atomic_write') as save:
            app.decide(argparse.Namespace(), self.root, self.state, {'pacman': ['new'], 'aur': []})
            save.assert_not_called()

    def test_corrupt_state_is_not_silently_reset(self):
        path = self.root / 'state.json'
        path.write_text('{broken')
        with patch.object(app, 'STATE_FILE', path), self.assertRaises(ValueError):
            app.load_state()


if __name__ == '__main__':
    unittest.main()
