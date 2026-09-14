// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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

import 'package:flutter_test/flutter_test.dart';

// The selector is a `tool/` script, not a library, so this is a relative
// import by design — `main()` only runs when the file is EXECUTED, so
// importing it is free.
import '../../tool/test_selector.dart';

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
    () {
      // #4177 — computed IN PROCESS. This used to spawn
      // `dart run tool/test_selector.dart`, which competes for the pub /
      // build-hook lock with everything else a full parallel
      // `flutter test` has in flight; it went red twice for that reason
      // while passing every time on its own. A contract guard that fails
      // for a reason unrelated to its contract is worse than no guard,
      // because the first red gets re-run, the second gets ignored, and
      // by the third nobody remembers what it protected.
      //
      // It also deletes the stdout parsing the subprocess forced: `dart
      // run` prepends "Running build hooks..." with no newline, so the
      // old version had to regex test paths back out of the noise.
      //
      // An empty `libChanged` is the same input the old invocation gave
      // (a README-only change): nothing under lib/ moved, so `affected`
      // is empty and the output is exactly the always-run bucket.
      final bucket = selectTests(const <String>{}).alwaysRun;

      expect(bucket, isNotEmpty,
          reason: 'the always-run bucket is never empty — an empty one '
              'means the selector stopped finding tests, not that the '
              'bucket shrank');

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

  test('a changed lib/ file pulls its dependents in, and not the world',
      () {
    // The other half of the selector's contract, now cheap to assert
    // because there is no subprocess: a real change selects the tests
    // that depend on it PLUS the always-run bucket, and nothing else.
    final selection = selectTests(const {'lib/core/domain/data_value.dart'});
    expect(selection.affected, isNotEmpty,
        reason: 'DataValue has dependents; selecting none would scope '
            'them out of their own PR');
    expect(selection.affected.intersection(selection.alwaysRun), isEmpty,
        reason: 'a test is in one bucket or the other, never counted twice');
  });
}
