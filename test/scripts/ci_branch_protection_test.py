# Copyright (c) 2026 Florian DITTGEN
# SPDX-License-Identifier: AGPL-3.0-or-later

import json
import os
from pathlib import Path
import subprocess
import tempfile
import textwrap
import unittest

SCRIPT = Path(__file__).resolve().parents[2] / 'scripts/configure_branch_protection.sh'
CHECKS = ['analyze', 'test (0)', 'test (1)', 'test (2)', 'test (3)',
          'codegen-drift', 'build-android', 'integration', 'startup-budget',
          'l10n-gate', 'independent-session-review']


class BranchProtectionTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.state = self.root / 'state.json'
        self.state.write_text(json.dumps({'contexts': CHECKS, 'strict': False,
                                         'enabled': True, 'mutations': []}))
        fake = self.root / 'gh'
        fake.write_text(textwrap.dedent('''\
            #!/usr/bin/env python3
            import json, os, sys
            from pathlib import Path
            p = Path(os.environ['PROTECTION_STATE'])
            state = json.loads(p.read_text())
            args = sys.argv[1:]
            method = args[args.index('-X') + 1] if '-X' in args else 'GET'
            if method != 'GET':
                state['mutations'].append(method)
                if method == 'PATCH':
                    state.update(json.load(sys.stdin))
                elif method == 'POST':
                    state['enabled'] = True
                p.write_text(json.dumps(state))
                print('{}')
            else:
                query = args[args.index('--jq') + 1]
                if query == '.contexts[]':
                    print('\\n'.join(state['contexts']))
                else:
                    print(json.dumps(state[query[1:]]))
            '''))
        fake.chmod(0o755)
        self.env = dict(os.environ, PATH=str(self.root) + os.pathsep + os.environ['PATH'],
                        PROTECTION_STATE=str(self.state))

    def tearDown(self):
        self.tmp.cleanup()

    def run_script(self, *args):
        return subprocess.run(['bash', str(SCRIPT), *args], env=self.env,
                              text=True, capture_output=True)

    def test_reapply_keeps_review_gate_and_enforces_admins_without_strict(self):
        self.state.write_text(json.dumps({'contexts': ['analyze'], 'strict': True,
                                         'enabled': False, 'mutations': []}))
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        actual = json.loads(self.state.read_text())
        self.assertEqual(set(actual['contexts']), set(CHECKS))
        self.assertFalse(actual['strict'])
        self.assertTrue(actual['enabled'])
        self.assertEqual(actual['mutations'], ['PATCH', 'POST'])

    def test_verify_is_read_only_and_accepts_required_review(self):
        result = self.run_script('--verify')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(json.loads(self.state.read_text())['mutations'], [])

    def test_verify_rejects_missing_review_or_disabled_admin_enforcement(self):
        for field, value in [('contexts', CHECKS[:-1]), ('enabled', False)]:
            state = {'contexts': CHECKS, 'strict': False, 'enabled': True, 'mutations': []}
            state[field] = value
            self.state.write_text(json.dumps(state))
            self.assertNotEqual(self.run_script('--verify').returncode, 0)
            self.assertEqual(json.loads(self.state.read_text())['mutations'], [])


if __name__ == '__main__':
    unittest.main()
