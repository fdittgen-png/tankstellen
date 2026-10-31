#!/usr/bin/env python3
# Copyright (c) 2026 Florian DITTGEN
# SPDX-License-Identifier: AGPL-3.0-or-later
"""One same-attempt plan. Dependency caches are never test evidence."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess

SCHEMA = 1
SDK = '3.44.9'
# Only these prose paths are known harmless. docs/** and *.md are NOT safe:
# fixtures, packaged help and Fastfiles can be consumed by the app or tests.
PROSE = ('docs/wiki/', 'docs/ci/', 'docs/decisions/')
PROSE_FILES = {'README.md', 'CONTRIBUTING.md', 'CHANGELOG.md',
               'docs/CONTRIBUTING.md', '.github/workflows/README.md'}


def git(*args):
    return subprocess.check_output(['git', *args])


def harmless(path):
    return path in PROSE_FILES or (path.endswith('.md') and path.startswith(PROSE))


def changed_paths(base, head):
    # No rename detection means a rename is represented by BOTH deletion and
    # addition. -z handles whitespace, Unicode and newlines without ambiguity.
    raw = git('diff', '--no-renames', '--name-only', '-z', base, head)
    if raw and not raw.endswith(b'\0'):
        raise ValueError('truncated git diff')
    return [os.fsdecode(p) for p in raw.split(b'\0') if p]


def validate_tests(tests, inventory, allow_empty=False):
    if not isinstance(tests, list) or (not tests and not allow_empty):
        raise ValueError('empty or invalid test list')
    if any(not isinstance(p, str) or p not in inventory for p in tests):
        raise ValueError('unknown or malformed test path')
    if len(tests) != len(set(tests)):
        raise ValueError('duplicate test path')
    return sorted(tests)


def build(event, base, out, selector=None):
    out.mkdir(parents=True, exist_ok=True)
    # Never accept stale output left by a failed attempt.
    (out / 'plan.json').unlink(missing_ok=True)
    head = git('rev-parse', 'HEAD').decode().strip()
    reason = 'non-PR full validation'
    paths = []
    diff = b''
    if event == 'pull_request':
        try:
            base = git('rev-parse', '--verify', base + '^{commit}').decode().strip()
            paths = changed_paths(base, head)
            diff = git('diff', '--unified=0', '--no-color', '--no-renames', base, head, '--', 'lib/')
            reason = 'complete base-to-candidate diff' if paths else 'empty diff: full validation'
        except (subprocess.CalledProcessError, ValueError):
            base = ''
            reason = 'unavailable base/diff: full validation'
    (out / 'changed-paths.json').write_text(json.dumps(paths, ensure_ascii=True))
    (out / 'changed-lines.diff').write_bytes(diff)
    inventory = sorted(p.as_posix() for p in Path('test').rglob('*_test.dart'))
    if not inventory:
        raise ValueError('no test inventory')
    docs = event == 'pull_request' and bool(paths) and all(map(harmless, paths))
    # Docs still run the real lint contracts (wiki parity, SPDX, etc.).
    tests = [p for p in inventory if p.startswith('test/lint/')] if docs else inventory
    measured = []
    applicable = False
    selector_exit = None
    # Only Dart lib/test edits are sound graph inputs. Native, tools,
    # dependency, runtime fixture or unknown paths require full validation.
    selectable = (event == 'pull_request' and bool(paths) and not docs and
                  all(harmless(p) or (p.startswith(('lib/', 'test/')) and
                      p.endswith('.dart') and Path(p).is_file()) for p in paths))
    command = selector or ['dart', 'tool/ci_selection.dart']
    if event == 'pull_request' and paths and not docs:
        result = subprocess.run([*command, str(out / 'changed-paths.json'),
                                 str(out / 'changed-lines.diff')],
                                capture_output=True, text=True)
        selector_exit = result.returncode
        (out / 'selector.stderr').write_text(result.stderr)
        try:
            if result.returncode:
                raise ValueError(f'selector exit {result.returncode}; discarded all stdout')
            selection = json.loads(result.stdout)
            selected = validate_tests(selection['tests'], inventory)
            measured = validate_tests(selection['coverage_tests'], inventory, True)
            if type(selection['applicable']) is not bool:
                raise ValueError('invalid coverage applicability')
            applicable = selection['applicable']
            if selectable:
                tests = sorted(set(selected) | set(measured))
                reason = selection['reason']
            else:
                reason = 'shared, deleted, native or runtime input: full suite'
        except (ValueError, KeyError, TypeError) as error:
            # Whole-suite coverage is the safe fallback; partial stdout cannot
            # authorize a subset, even if it starts with valid test paths.
            tests = inventory
            measured = inventory
            applicable = True
            reason = f'full fallback: {error}'
    elif docs:
        reason = 'prose-only: real lint contracts, no app build'
    if event != 'pull_request':
        measured = inventory
    measured = sorted(set(tests) & set(measured))
    rest = sorted(set(tests) - set(measured))
    shards = [{'plain': rest[i::4], 'coverage': measured[i::4]} for i in range(4)]
    plan = {'schema': SCHEMA, 'source': head, 'base': base,
            'event': event, 'run': os.environ.get('GITHUB_RUN_ID', 'local'),
            'attempt': os.environ.get('GITHUB_RUN_ATTEMPT', '1'),
            'sdk': SDK, 'flavor': 'default-tests',
            'tree': git('rev-parse', 'HEAD^{tree}').decode().strip(),
            'docs': docs, 'code': not docs and any(not p.startswith('test/') and not harmless(p) for p in paths),
            'deps': not docs and (event != 'pull_request' or any(p.startswith(('pubspec', '.github/', 'scripts/', 'tool/')) for p in paths)),
            'applicable': applicable, 'selector_exit': selector_exit,
            'reason': reason, 'tests': tests, 'shards': shards,
            'diff_sha256': hashlib.sha256(diff).hexdigest()}
    if not paths and not docs:
        plan['code'] = True
    (out / 'plan.json').write_text(json.dumps(plan, indent=2) + '\n')
    for key in ('docs', 'code', 'deps', 'applicable'):
        with open(os.environ.get('GITHUB_OUTPUT', os.devnull), 'a') as output:
            print(f'{key}={str(plan[key]).lower()}', file=output)
    summary = f"### CI plan\n\nSource `{head}`, base `{base or 'unavailable'}`.\n\n{reason}; {len(tests)} files, four shards. Flutter {SDK}.\n"
    print(summary)
    if os.environ.get('GITHUB_STEP_SUMMARY'):
        with open(os.environ['GITHUB_STEP_SUMMARY'], 'a') as output:
            output.write(summary)
    return plan


def load(out):
    plan = json.loads((out / 'plan.json').read_text())
    for key, expected in [('schema', SCHEMA), ('sdk', SDK),
                          ('source', git('rev-parse', 'HEAD').decode().strip()),
                          ('tree', git('rev-parse', 'HEAD^{tree}').decode().strip()),
                          ('run', os.environ.get('GITHUB_RUN_ID', 'local')),
                          ('attempt', os.environ.get('GITHUB_RUN_ATTEMPT', '1'))]:
        if plan.get(key) != expected:
            raise ValueError(f'plan identity mismatch: {key}')
    if hashlib.sha256((out / 'changed-lines.diff').read_bytes()).hexdigest() != plan['diff_sha256']:
        raise ValueError('plan diff mismatch')
    inventory = {p.as_posix() for p in Path('test').rglob('*_test.dart')}
    tests = validate_tests(plan['tests'], inventory)
    shards = plan['shards']
    if len(shards) != 4:
        raise ValueError('expected four shards')
    allocated = [p for shard in shards for kind in ('plain', 'coverage') for p in shard[kind]]
    if sorted(allocated) != tests:
        raise ValueError('shards must cover selected tests exactly once')
    return plan


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['build', 'verify'])
    parser.add_argument('--event', default=os.environ.get('GITHUB_EVENT_NAME', 'pull_request'))
    parser.add_argument('--base', default=os.environ.get('BASE_SHA', ''))
    parser.add_argument('--out', type=Path, default=Path('ci-plan'))
    args = parser.parse_args()
    if args.action == 'build':
        build(args.event, args.base, args.out)
    else:
        load(args.out)


if __name__ == '__main__':
    main()
