"""Run with python -m unittest discover -s tests -p 'test_voxtype_cleanup.py'."""
from pathlib import Path
import subprocess
import sys
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'dot_local/bin/executable_voxtype-cleanup'

class CleanupTests(unittest.TestCase):
    def check_cases(self, cases):
        for source, expected in cases:
            with self.subTest(source=source):
                result = subprocess.run([sys.executable, str(SCRIPT)], input=source,
                                        text=True, capture_output=True, check=True)
                self.assertEqual(result.stdout, expected)
                self.assertEqual(result.stderr, '')

    def test_initial_fillers(self):
        self.check_cases([
            ('Um, keep useEffect and um_count in mm with ER.', 'keep useEffect and um_count in mm with ER.'),
            ('Keep this. Uh, keep that.', 'Keep this. keep that.'),
            ('', ''),
        ])

    def test_explicit_simple_corrections(self):
        self.check_cases([
            ('Set timeout to 15, no I mean 50 milliseconds. Keep retries.', 'Set timeout to 50 milliseconds. Keep retries.'),
            ('Sätt timeout till femton nej jag menar femtio millisekunder.', 'Sätt timeout till femtio millisekunder.'),
        ])

    def test_preservation(self):
        sources = [
            'The variable is named um and unit is mm.',
            'Write "15, no I mean 50" verbatim.',
            'twenty five no I mean fifty milliseconds',
            '1.5 no I mean 2.5 seconds',
            'minus fifteen no I mean fifty seconds',
            '15 no I mean fifty five milliseconds',
            "Do not delete parse_config or rename HTTPServer.",
        ]
        self.check_cases([(source, source) for source in sources])

if __name__ == '__main__':
    unittest.main()
