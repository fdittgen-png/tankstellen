// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

// #4347 — the CI wiring of the pre-merge changed-line coverage policy.
// The policy's behaviour is executed in coverage_policy_test.dart; these
// guards pin that ci.yml runs it on PRs as an ADVISORY check (maintainer
// decision: warn first) behind a one-line COVERAGE_POLICY_ENFORCE switch,
// that record-green and branch protection do not depend on it, and that
// the post-merge 40 % floor stays where it was.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

YamlMap _jobs(String path) =>
    (loadYaml(File(path).readAsStringSync()) as YamlMap)['jobs'] as YamlMap;

List<YamlMap> _steps(YamlMap job) =>
    (job['steps'] as YamlList).cast<YamlMap>().toList();

YamlMap _step(YamlMap job, bool Function(YamlMap s) where) =>
    _steps(job).firstWhere(where, orElse: () => YamlMap());

String _run(YamlMap step) => (step['run'] ?? '') as String;

List<String> _needs(YamlMap job) => switch (job['needs']) {
      final String one => [one],
      final YamlList many => many.cast<String>().toList(),
      _ => const [],
    };

void main() {
  late YamlMap jobs;

  setUpAll(() => jobs = _jobs('.github/workflows/ci.yml'));

  group('PR shards collect the coverage the policy judges', () {
    late YamlMap shards;
    setUpAll(() => shards = jobs['test'] as YamlMap);

    test('coverage collection is decided from the diff by the policy tool',
        () {
      final decide = _step(shards, (s) => s['id'] == 'cov');
      expect(_run(decide), contains('git diff --unified=0'));
      expect(_run(decide), contains('--applicable-only'));
      expect(decide['if'], contains("github.event_name == 'pull_request'"));
    });

    YamlMap prShard() => _step(
        shards,
        (s) =>
            '${s['name']}'.contains('PR') && _run(s).contains('flutter test'));

    test('without applicable changes the PR shard runs exactly as before', () {
      final shard = prShard();
      expect((shard['env'] as YamlMap)['COLLECT_COVERAGE'],
          r'${{ steps.cov.outputs.applicable }}');
      final beforeCoverage =
          _run(shard).substring(0, _run(shard).indexOf('exit \$?'));
      expect(beforeCoverage, contains('if [ "\$COLLECT_COVERAGE" != "true" ]'));
      expect(beforeCoverage, isNot(contains('--coverage')));
    });

    test('with applicable changes only the tests of changed lib/ files run '
        'with --coverage, the rest without', () {
      final run = _run(prShard());
      final coverageBranch = run.substring(run.indexOf('exit \$?'));
      expect(coverageBranch, contains('--coverage-tests > coverage_tests.txt'));
      // The measured subset carries --coverage; the remainder does not.
      expect(coverageBranch,
          contains('flutter test "\${MINE[@]}" --coverage'));
      final restCall = RegExp(r'flutter test "\$\{REST\[@\]\}"[^|]*')
          .firstMatch(coverageBranch)!
          .group(0)!;
      expect(restCall, isNot(contains('--coverage')));
      expect(restCall, contains('--total-shards=4'));
      // Every shard leaves a report behind, and a failure is not masked.
      expect(coverageBranch, contains(': > coverage/lcov.info'));
      expect(coverageBranch, contains('exit "\$status"'));
    });

    test('each shard uploads its report and a missing one is an error', () {
      final upload = _step(
          shards,
          (s) =>
              '${(s['with'] as YamlMap?)?['name']}'.startsWith('pr-coverage'));
      final w = upload['with'] as YamlMap;
      expect(w['name'], r'pr-coverage-shard-${{ matrix.shard }}');
      expect(w['if-no-files-found'], 'error');
      expect(upload['if'], contains("steps.cov.outputs.applicable == 'true'"));
    });

    test('the matrix job is never skipped at job level (#2417)', () {
      expect(shards.containsKey('if'), isFalse);
      expect(((shards['strategy'] as YamlMap)['matrix'] as YamlMap)['shard'],
          [0, 1, 2, 3]);
    });
  });

  group('the coverage-policy job is advisory until switched on', () {
    late YamlMap job;
    setUpAll(() => job = jobs['coverage-policy'] as YamlMap);

    YamlMap policyStep() =>
        _step(job, (s) => _run(s).contains('dart tool/coverage_policy.dart "'));

    test('is a single-context job after the shards, on PRs', () {
      expect(job.containsKey('strategy'), isFalse,
          reason: 'a matrix would need per-step gating to stay required');
      expect(_needs(job), containsAll(['test', 'green-gate']));
      expect(job['if'], contains("github.event_name == 'pull_request'"));
      expect(job['if'], contains("needs.green-gate.outputs.cached != 'true'"));
    });

    test('the one-line switch exists and is OFF', () {
      expect((job['env'] as YamlMap)['COVERAGE_POLICY_ENFORCE'], 'false');
      expect(job.containsKey('continue-on-error'), isFalse,
          reason: 'job-level continue-on-error still paints a red X');
    });

    test('setup, diff and download cannot fail the job while advisory', () {
      for (final step in _steps(job)) {
        if ('${step['uses']}'.startsWith('actions/checkout')) continue;
        if (identical(step, policyStep())) continue;
        expect(step['continue-on-error'],
            r"${{ env.COVERAGE_POLICY_ENFORCE != 'true' }}",
            reason: '${step['name'] ?? step['uses']}');
      }
    });

    test('names all four shard reports and the switch picks the level', () {
      final run = _run(policyStep());
      expect(run, contains('for shard in 0 1 2 3'));
      expect(run,
          contains(r'--lcov "pr-coverage/pr-coverage-shard-${shard}/lcov.info"'));
      expect(run, contains('--annotation-level "\$LEVEL"'));
      expect(run, contains('--summary "\$GITHUB_STEP_SUMMARY"'));
    });

    test('diffs against the PR base with the same command as the shards', () {
      final shardDiff =
          _run(_step(jobs['test'] as YamlMap, (s) => s['id'] == 'cov'));
      final jobDiff = _run(_step(job, (s) => s['id'] == 'cov'));
      expect(jobDiff, shardDiff,
          reason: 'shards and gate must agree on what "applicable" means');
    });

    // The policy step's own shell, EXECUTED with a stub `dart` that exits
    // with each of the tool's codes, in both switch positions.
    group('executed', () {
      late Directory tmp;
      setUp(() => tmp = Directory.systemTemp.createTempSync('cov_gate_'));
      tearDown(() => tmp.deleteSync(recursive: true));

      ({int code, String out, String dartArgs}) runStep(
          {required String enforce, required int toolExit}) {
        final bin = Directory('${tmp.path}/bin')..createSync();
        final argsLog = File('${tmp.path}/dart_args.txt');
        final stub = File('${bin.path}/dart')
          ..writeAsStringSync('#!/bin/sh\n'
              'echo "\$@" > "${argsLog.path}"\n'
              'exit $toolExit\n');
        Process.runSync('chmod', ['+x', stub.path]);
        final script = File('${tmp.path}/step.sh')
          ..writeAsStringSync(_run(policyStep()));
        final r = Process.runSync('bash', ['-e', script.path],
            workingDirectory: tmp.path,
            environment: {
              'PATH': '${bin.path}:${Platform.environment['PATH']}',
              'COVERAGE_POLICY_ENFORCE': enforce,
              'APPLICABLE': 'true',
              'GITHUB_STEP_SUMMARY': '${tmp.path}/summary.md',
            });
        return (
          code: r.exitCode,
          out: '${r.stdout}${r.stderr}',
          dartArgs: argsLog.existsSync() ? argsLog.readAsStringSync() : '',
        );
      }

      for (final toolExit in [1, 2, 3]) {
        test('advisory: tool exit $toolExit reports a warning and passes', () {
          final r = runStep(enforce: 'false', toolExit: toolExit);
          expect(r.code, 0, reason: r.out);
          expect(r.out, contains('::warning title=Changed-line coverage'));
          expect(r.dartArgs, contains('--annotation-level warning'));
        });

        test('enforcing: tool exit $toolExit fails the job', () {
          final r = runStep(enforce: 'true', toolExit: toolExit);
          expect(r.code, toolExit, reason: r.out);
          expect(r.dartArgs, contains('--annotation-level error'));
        });
      }

      test('a passing policy passes in both modes, silently', () {
        for (final enforce in ['false', 'true']) {
          final r = runStep(enforce: enforce, toolExit: 0);
          expect(r.code, 0, reason: r.out);
          expect(r.out, isNot(contains('::warning')));
        }
      });
    });

    test('record-green does NOT depend on it while it is advisory', () {
      final record = jobs['record-green'] as YamlMap;
      expect(_needs(record), isNot(contains('coverage-policy')));
      expect('${record['if']}', isNot(contains('coverage-policy')));
    });

    test('the green marker keys stay identical between probe and save', () {
      String keyOf(YamlMap j) {
        final cache =
            _step(j, (s) => '${s['uses']}'.startsWith('actions/cache'));
        return '${(cache['with'] as YamlMap)['key']}';
      }

      expect(keyOf(jobs['green-gate'] as YamlMap),
          keyOf(jobs['record-green'] as YamlMap));
    });
  });

  group('post-merge backstop stays in place', () {
    test('coverage-merge keeps the explicit 40 % floor on the full suite', () {
      final merge = jobs['coverage-merge'] as YamlMap;
      expect(merge['if'], "github.event_name != 'pull_request'");
      final gate = _step(merge, (s) => s['name'] == 'Check coverage threshold');
      expect(_run(gate).trim(), 'bash scripts/check_coverage.sh --threshold 40');
    });

    test('and reports policy drift on the full-suite coverage', () {
      final merge = jobs['coverage-merge'] as YamlMap;
      final drift = _step(merge, (s) => _run(s).contains('pushed-lines.diff'));
      expect(_run(drift), contains('--lcov coverage/lcov.info'));
      final checkout =
          _step(merge, (s) => '${s['uses']}'.startsWith('actions/checkout'));
      expect((checkout['with'] as YamlMap)['fetch-depth'], 0);
    });
  });

  group('required-check wiring matches the switch', () {
    bool listedInTarget() {
      final script =
          File('scripts/configure_branch_protection.sh').readAsStringSync();
      final start = script.indexOf('TARGET_CHECKS=(');
      final end = script.indexOf('\n)', start);
      return script.substring(start, end).contains('"coverage-policy"');
    }

    test('required iff stubbed for docs-only PRs', () {
      final stubbed = _jobs('.github/workflows/ci-docs-stub.yml')
          .containsKey('coverage-policy');
      expect(stubbed, listedInTarget(),
          reason: 'a required context needs a docs-only stub, and a stub '
              'for a non-required job is noise');
    });

    test('an advisory job is never a required check', () {
      final enforce = ((jobs['coverage-policy'] as YamlMap)['env']
          as YamlMap)['COVERAGE_POLICY_ENFORCE'];
      if (enforce != 'true') {
        expect(listedInTarget(), isFalse,
            reason: 'a required check that always passes proves nothing');
      }
    });
  });
}
