#!/usr/bin/env python3
# Copyright (c) 2026 Florian DITTGEN
# SPDX-License-Identifier: AGPL-3.0-or-later
"""Run each planned file once; retain the original exit and machine stream."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import time

from plan import load


def run(files, coverage, output, executable='flutter'):
    command = [executable, 'test', '--no-pub', '--machine',
               '--exclude-tags=network,flaky', *(['--coverage'] if coverage else []), *files]
    if not files:
        return {'files': 0, 'status': 'empty-allocation', 'exit': 0, 'seconds': 0}
    started = time.monotonic()
    with output.open('w') as stream:
        result = subprocess.run(command, stdout=stream, stderr=subprocess.STDOUT)
    output.with_suffix('.exit.json').write_text(json.dumps({
        'command': command, 'exit': result.returncode,
        'seconds': time.monotonic() - started}) + '\n')
    # Timings are observations, never substituted for the process verdict.
    counts = {'passed': 0, 'failed': 0, 'skipped': 0}
    timings = []
    tests = {}
    suites = {}
    finished = set()
    stream_errors = []
    file_times = {}
    done = False
    shown_errors = 0
    for line in output.read_text(errors='replace').splitlines():
        try:
            event = json.loads(line)
        except ValueError:
            continue  # native build-hook diagnostics are retained verbatim
        if not isinstance(event, dict):
            continue  # build hooks may emit JSON arrays/scalars, not test events
        if event.get('type') == 'suite':
            suite = event['suite']
            suites[suite['id']] = suite.get('path', '')
        elif event.get('type') == 'testStart':
            test = event['test']
            if test['id'] in tests:
                stream_errors.append(f"duplicate test id {test['id']}")
            tests[test['id']] = (test.get('name', ''), event.get('time', 0),
                                 suites.get(test.get('suiteID'), 'unknown'))
        elif event.get('type') == 'testDone':
            test_id = event['testID']
            if test_id in finished or test_id not in tests:
                stream_errors.append(f'duplicate or missing test start {test_id}')
            finished.add(test_id)
            verdict = 'skipped' if event.get('skipped') else ('passed' if event.get('result') == 'success' else 'failed')
            counts[verdict] += 1
            name, start, path = tests.get(test_id, ('unknown', 0, 'unknown'))
            end = event.get('time', start)
            timings.append({'id': test_id, 'name': name, 'file': path,
                            'milliseconds': end - start, 'result': verdict})
            bounds = file_times.setdefault(path, [start, end])
            bounds[0], bounds[1] = min(bounds[0], start), max(bounds[1], end)
        elif event.get('type') == 'error':
            if shown_errors < 5:
                print(str(event.get('error', ''))[:1500], flush=True)
            shown_errors += 1
        elif event.get('type') == 'done':
            if done:
                stream_errors.append('duplicate done event')
            done = True
            if event.get('success') is not True:
                stream_errors.append('stream did not report success')
    code = result.returncode
    if code == 0 and (not done or stream_errors or not finished or set(tests) != finished or counts['failed']):
        code = 2
    record = {'files': len(files), 'command': command, 'exit': result.returncode,
              'validated_exit': code, 'complete': done, 'seconds': time.monotonic() - started,
              'counts': counts, 'timings': timings, 'stream_errors': stream_errors,
              'file_timings': [{'path': p, 'milliseconds': end - start}
                               for p, (start, end) in file_times.items()]}
    print(f"{output.name}: {len(files)} files, exit {result.returncode}, {counts}")
    return record


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--shard', type=int, choices=range(4), required=True)
    args = parser.parse_args()
    plan = load(Path('ci-plan'))
    shard = plan['shards'][args.shard]
    output = Path('ci-results')
    output.mkdir(exist_ok=True)
    Path('coverage').mkdir(exist_ok=True)
    # Each runner starts with an empty report; no prior build output is restored.
    Path('coverage/lcov.info').unlink(missing_ok=True)
    results = []
    for kind in ('plain', 'coverage'):
        record = run(shard[kind], kind == 'coverage', output / f'{kind}.jsonl')
        results.append(record)
        (output / 'result.json').write_text(json.dumps({'source': plan['source'],
            'base': plan['base'], 'run': plan['run'], 'attempt': plan['attempt'],
            'shard': args.shard, 'results': results}, indent=2) + '\n')
    if not Path('coverage/lcov.info').exists():
        # An empty allocation / tag-excluded slice is explicit in result.json.
        if not shard['coverage'] or results[-1]['exit'] == 79:
            Path('coverage/lcov.info').touch()
        elif results[-1]['exit'] == 0:
            raise SystemExit('coverage slice ran but produced no report')
    codes = [r.get('validated_exit', r['exit']) for r in results]
    raise SystemExit(next((code for code in codes if code not in (0, 79)), 0))


if __name__ == '__main__':
    main()
