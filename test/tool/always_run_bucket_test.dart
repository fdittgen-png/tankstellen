// Regression test for the always-run bucket (#1593 / Epic #1591).
//
// Pins the load-bearing cross-cutting tests so an accidental
// `package:tankstellen/...` import (or any other transitive lib/ pull)
// trips CI immediately rather than silently moving the test out of
// the always-run set.
//
// Pairs with `docs/test-always-run-bucket-2026-05.md` which catalogues
// the full bucket. This test only asserts the *contract-bearing*
// subset — lint guards, ARB parity, ADR format, security manifests —
// because those tests' value depends on running on every PR.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _selectorPath = 'tool/test_selector.dart';

/// The contract-bearing always-run tests. If one of these accidentally
/// gains a transitive `lib/` import, this test fails BEFORE the test
/// silently starts being scoped-out of unrelated PRs.
const _mustStayInBucket = <String>{
  // Lint contracts — every PR must trip lint regressions.
  'test/lint/no_silent_catch_test.dart',
  'test/accessibility/icon_button_tooltip_coverage_test.dart',
  'test/lint/no_hardcoded_ui_strings_test.dart',
  'test/lint/declared_dependencies_test.dart',
  'test/lint/arb_fragments_consistency_test.dart',
  'test/lint/prefer_const_constructors_test.dart',
  'test/lint/no_raw_appbar_in_features_test.dart',
  'test/lint/catch_block_stacktrace_coverage_test.dart',
  // Localisation parity — global invariant.
  'test/i18n/arb_key_parity_test.dart',
  'test/l10n/localization_completeness_test.dart',
  // Docs / ADR / privacy — file-shape contracts.
  'test/docs/adr_format_test.dart',
  'test/docs/privacy_policy_test.dart',
  // Security manifests — must check on every PR.
  'test/security/android_manifest_security_test.dart',
  'test/security/no_hardcoded_secrets_test.dart',
  'test/security/no_plaintext_station_endpoints_test.dart',
  // CI workflow shape — protects branch-protection contract.
  'test/ci/ci_workflow_test.dart',
};

void main() {
  test(
    'every contract-bearing always-run test stays in the bucket '
    '(no accidental lib/ imports — #1593 regression guard)',
    () async {
      // Run the selector with a non-lib change. The output is exactly
      // the always-run bucket — affected set is empty for this input.
      final p = await Process.start(
        'dart',
        ['run', _selectorPath, '-'],
        runInShell: false,
      );
      p.stdin.writeln('README.md');
      await p.stdin.close();
      final stdoutF =
          p.stdout.transform(const SystemEncoding().decoder).join();
      final exitCode = await p.exitCode;
      final stdout = await stdoutF;
      expect(exitCode, 0,
          reason: 'selector should exit 0 when the always-run bucket '
              'is non-empty (which it always is)');

      // Dart's `pub get` / build-runner prepends a chatty `Running
      // build hooks...` (no newline before the first selector line)
      // to stdout when run via `dart run`. The pragmatic fix: keep
      // only the substring of each split line that matches a test
      // file path. Anything before `test/` is build-runner noise.
      final pathRe = RegExp(r'(test/[^\s]+_test\.dart)');
      final bucket = <String>{};
      for (final line in stdout.split('\n')) {
        for (final m in pathRe.allMatches(line)) {
          bucket.add(m.group(1)!);
        }
      }

      for (final required in _mustStayInBucket) {
        expect(
          bucket,
          contains(required),
          reason: 'Contract-bearing test $required must stay in the '
              'always-run bucket. If a recent change added a '
              'package:tankstellen import to it, replace the import with '
              'a dart:io File read from disk so the test stays cross-'
              'cutting. See docs/test-always-run-bucket-2026-05.md.',
        );
      }
    },
  );
}
