// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

Map<String, YamlMap> workflows() => {
  for (final file in Directory(
    '.github/workflows',
  ).listSync().whereType<File>())
    if (file.path.endsWith('.yml'))
      file.uri.pathSegments.last: loadYaml(file.readAsStringSync()) as YamlMap,
};

void main() {
  test(
    'every workflow bounds runners, scopes permissions and preserves manual runs',
    () {
      for (final MapEntry(key: name, value: workflow) in workflows().entries) {
        expect(workflow['permissions'], isNotNull, reason: name);
        final concurrency = workflow['concurrency'] as YamlMap;
        expect(concurrency['cancel-in-progress'], isNot(true), reason: name);
        final group = '${concurrency['group']}';
        if (!{'pages.yml', 'fdroid-publish.yml'}.contains(name)) {
          expect(
            group,
            startsWith(name.replaceFirst('.yml', '')),
            reason: name,
          );
        } else {
          expect(group, 'pages');
        }
        for (final job
            in (workflow['jobs'] as YamlMap).values.cast<YamlMap>()) {
          if (!job.containsKey('runs-on')) continue;
          expect(job['timeout-minutes'], greaterThan(0), reason: name);
        }
      }
    },
  );

  test('main validation only signs and publishes on a version-tag push', () {
    final ci = workflows()['ci.yml']!;
    final jobs = ci['jobs'] as YamlMap;
    final steps = jobs['build-android']['steps'] as YamlList;
    for (final step in steps.cast<YamlMap>()) {
      final run = '${step['run']}';
      if (run.contains('--release') ||
          step['name'] == 'Decode signing keystore') {
        expect(step['if'], contains("github.event_name == 'push'"));
        expect(step['if'], contains("startsWith(github.ref, 'refs/tags/v')"));
      }
    }
    expect(jobs['release']['if'], contains("github.event_name == 'push'"));
    expect(
      jobs['release']['needs'],
      containsAll(['test', 'codegen-drift', 'l10n-gate']),
    );
  });

  test(
    'release train passes exactly one source identity to every build leg',
    () {
      final all = workflows();
      final jobs = all['release-train.yml']!['jobs'] as YamlMap;
      for (final leg in ['android-beta', 'ios-testflight', 'fdroid']) {
        expect(jobs[leg]['needs'], contains('resolve'));
        expect(
          jobs[leg]['with']['source_sha'],
          r'${{ needs.resolve.outputs.source_sha }}',
        );
        final path = '${jobs[leg]['uses']}'.split('/').last;
        final called = all[path]!;
        expect(
          called['on']['workflow_call']['inputs']['source_sha']['required'],
          isTrue,
        );
        final text = File('.github/workflows/$path').readAsStringSync();
        expect(text, contains('ref: \${{ inputs.source_sha || github.sha }}'));
        expect(text, contains('github.workflow_sha'));
        expect(text, contains('actions/source-identity'));
      }
    },
  );

  test('same-attempt coverage aggregation demands all four reports', () {
    final jobs = workflows()['ci.yml']!['jobs'] as YamlMap;
    final merge = (jobs['coverage-merge']['steps'] as YamlList)
        .cast<YamlMap>()
        .firstWhere((s) => s['name'] == 'Merge shard lcov files');
    expect(merge['run'], contains('for shard in 0 1 2 3'));
    expect(merge['run'], contains('test -f'));
    expect(merge['run'], contains('github.run_attempt'));
  });

  test('publication locks remain global for the same destination', () {
    final all = workflows();
    for (final name in [
      'daily-beta',
      'ios-testflight',
      'daily-github-release',
      'deploy',
      'promote-release',
      'release-train',
    ]) {
      expect(all['$name.yml']!['concurrency']['group'], name);
    }
  });
}
