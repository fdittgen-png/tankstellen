#!/usr/bin/env python3
# Copyright (c) 2026 Florian DITTGEN
# SPDX-License-Identifier: AGPL-3.0-or-later
import contextlib
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import unittest.mock

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'scripts/ci'))
from plan import build, changed_paths, load
from run_shard import run
from branch_guard import validate


class PlanTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.old = Path.cwd()
        os.chdir(self.tmp.name)
        self.git('init', '-q')
        self.git('config', 'user.email', 'ci@example.invalid')
        self.git('config', 'user.name', 'CI test')
        Path('.git/info/exclude').write_text('selector.py\nci-plan/\n')
        for path in ['lib/a.dart', 'test/a_test.dart', 'test/b_test.dart',
                     'test/lint/wiki_test.dart', 'docs/wiki/Guide.md']:
            self.write(path)
        self.commit()
        self.base = self.git('rev-parse', 'HEAD').strip()
        self.selector = Path('selector.py').resolve()
        self.selector.write_text('import json\nprint(json.dumps({"tests":["test/a_test.dart"],'
                                 '"coverage_tests":[],"applicable":False,"reason":"selected"}))\n')

    def tearDown(self):
        os.chdir(self.old)
        self.tmp.cleanup()

    def git(self, *args):
        return subprocess.check_output(['git', *args], stderr=subprocess.DEVNULL).decode()

    def write(self, path, content='fixture\n'):
        p = Path(path)
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(content)

    def commit(self):
        self.git('add', '.')
        self.git('commit', '-qm', 'fixture')

    def plan(self, base=None, event='pull_request'):
        with contextlib.redirect_stdout(io.StringIO()):
            return build(event, base or self.base, Path('ci-plan'), [sys.executable, str(self.selector)])

    def test_docs_only_runs_real_lints_but_mixed_code_does_not_skip(self):
        self.write('docs/wiki/Guide.md', 'updated\n')
        self.commit()
        p = self.plan()
        self.assertTrue(p['docs'])
        self.assertEqual(p['tests'], ['test/lint/wiki_test.dart'])
        self.write('lib/a.dart', 'int a = 1;\n')
        self.commit()
        p = self.plan()
        self.assertFalse(p['docs'])
        self.assertTrue(p['code'])
        self.assertEqual(p['tests'], ['test/a_test.dart'])

    def test_complete_diff_includes_both_rename_paths_and_unusual_names(self):
        original = 'lib/a.dart'
        target = 'lib/sp ace-é\nrenamed.dart'
        Path(original).rename(target)
        for i in range(350):
            self.write(f'docs/wiki/{i}.md')
        self.commit()
        paths = changed_paths(self.base, 'HEAD')
        self.assertIn(original, paths)
        self.assertIn(target, paths)
        self.assertEqual(len(paths), 352)
        p = self.plan()
        self.assertFalse(p['docs'])
        self.assertEqual(len(p['tests']), 3)  # rename/delete => full suite

    def test_executable_packaged_fixture_and_unknown_paths_force_full(self):
        for path in ['ios/fastlane/Fastfile', 'docs/help/guide.md', 'test/data.json',
                     '.github/workflows/ci.yml', 'tool/new.dart', 'build.yaml',
                     'third_party/plugin/file.dart', 'pubspec.lock']:
            self.write(path)
        self.commit()
        p = self.plan()
        self.assertFalse(p['docs'])
        self.assertTrue(p['deps'])
        self.assertEqual(len(p['tests']), 3)

    def test_missing_base_empty_diff_and_non_pr_all_run_full(self):
        for base, event in [('absent', 'pull_request'),
                            (self.base, 'pull_request'), (self.base, 'workflow_dispatch')]:
            p = self.plan(base, event)
            self.assertEqual(len(p['tests']), 3)
            self.assertTrue(p['code'])
            self.assertFalse(p['docs'])

    def test_entire_selector_output_is_validated_before_accepting(self):
        self.write('lib/a.dart', 'changed\n')
        self.commit()
        for code in [
            'print("test/a_test.dart"); raise SystemExit(1)',
            'print(\'noise {"tests":[]}\')',
            'print(\'{"tests": [], "coverage_tests":[], "applicable":false}\')',
            'print(\'{"tests":["test/missing_test.dart"]}\')',
            'print(\'{"tests":["test/a_test.dart","test/a_test.dart"]}\')',
            'import os, signal; os.kill(os.getpid(), signal.SIGTERM)',
        ]:
            self.selector.write_text(code + '\n')
            p = self.plan()
            self.assertEqual(len(p['tests']), 3, code)
            self.assertTrue(p['applicable'])
            self.assertIn('full fallback', p['reason'])

    def test_plan_partition_and_attempt_source_diff_validation(self):
        self.write('lib/a.dart', 'changed\n')
        self.commit()
        p = self.plan()
        self.assertEqual(load(Path('ci-plan')), p)
        allocated = [t for s in p['shards'] for k in ['plain', 'coverage'] for t in s[k]]
        self.assertEqual(sorted(allocated), sorted(p['tests']))
        with unittest.mock.patch.dict(os.environ, {'GITHUB_RUN_ATTEMPT': '99'}):
            with self.assertRaisesRegex(ValueError, 'attempt'):
                load(Path('ci-plan'))
        Path('ci-plan/changed-lines.diff').write_text('tampered')
        with self.assertRaisesRegex(ValueError, 'diff mismatch'):
            load(Path('ci-plan'))
        self.plan()
        self.write('lib/a.dart', 'next candidate\n')
        self.commit()
        with self.assertRaisesRegex(ValueError, 'source'):
            load(Path('ci-plan'))

    def test_same_source_new_base_creates_new_plan_not_green_cache(self):
        self.write('lib/a.dart', 'changed\n')
        self.commit()
        p = self.plan()
        q = self.plan(self.git('rev-parse', 'HEAD').strip())
        self.assertEqual(p['source'], q['source'])
        self.assertNotEqual(p['base'], q['base'])
        self.assertNotEqual(p['tests'], q['tests'])

    def test_runner_preserves_failed_exit_and_rejects_incomplete_success(self):
        exe = Path('fake-flutter').resolve()
        valid = '\n'.join(json.dumps(e) for e in [[],
            {'type': 'testStart', 'test': {'id': 1, 'name': 'case'}},
            {'type': 'testDone', 'testID': 1, 'result': 'success'},
            {'type': 'done', 'success': True}])
        duplicate = valid.replace('\n{"type": "done"', '\n{"type": "testDone", "testID": 1, "result": "success"}\n{"type": "done"')
        for code, stream, expected in [(7, valid, 7),
                                        (0, '{"type":"testStart","test":{"id":1}}', 2),
                                        (0, duplicate, 2), (0, valid, 0)]:
            exe.write_text(f'#!/bin/sh\nprintf \'%s\\n\' \'{stream}\'\nexit {code}\n')
            exe.chmod(0o755)
            record = run(['test/a_test.dart'], False, Path('machine.jsonl'), str(exe))
            self.assertEqual(record['exit'], code)
            self.assertEqual(record['validated_exit'], expected)
            self.assertEqual(Path('machine.jsonl').read_text().strip(), stream)
        record = run([], False, Path('unused'), str(exe))
        self.assertEqual(record['status'], 'empty-allocation')
        self.assertFalse(Path('unused').exists())


class BranchGuardTests(unittest.TestCase):
    def record(self, local, remote, sha='a' * 40):
        return f'{local} {sha} {remote} {"b" * 40}\n'

    def test_expected_branch_only(self):
        validate('ci/4451', self.record('refs/heads/ci/4451', 'refs/heads/ci/4451'))
        for branch, local, remote in [
            ('master', 'refs/heads/master', 'refs/heads/master'),
            ('other', 'refs/heads/ci/4451', 'refs/heads/ci/4451'),
            ('ci/4451', 'refs/heads/ci/4451', 'refs/heads/other'),
            ('', 'HEAD', 'refs/heads/ci/4451')]:
            with self.assertRaises(ValueError):
                validate(branch, self.record(local, remote))

    def test_release_tags_and_deletions(self):
        validate('master', self.record('refs/tags/v6', 'refs/tags/v6'))
        validate('master', self.record('(delete)', 'refs/heads/old', '0' * 40))


if __name__ == '__main__':
    unittest.main()
