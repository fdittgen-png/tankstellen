import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Smoke test for `tool/audit_catalog_diesel_gaps.dart` (#1396).
///
/// The audit script is a developer tool, not part of the runtime
/// build, so this test only proves three things:
///
///   1. The script exists at the documented path,
///   2. It runs to completion against the current
///      `assets/reference_vehicles/vehicles.json`,
///   3. The output looks like the markdown table the maintainer is
///      meant to paste into a PR comment (header + at least one
///      "covered" row, since this PR ships several).
///
/// We don't assert on the *contents* of the missing-diesels list —
/// the curated table inside the script will drift over time and
/// pinning specific rows here would create an unrelated maintenance
/// burden. The detector / catalog tests already cover the runtime
/// behaviour the user observes.
void main() {
  test('audit_catalog_diesel_gaps.dart exists', () {
    expect(File('tool/audit_catalog_diesel_gaps.dart').existsSync(), isTrue);
  });

  test('audit_catalog_diesel_gaps.dart runs and emits the markdown header',
      () async {
    final result = await Process.run(
      'dart',
      <String>['run', 'tool/audit_catalog_diesel_gaps.dart'],
      runInShell: true,
    );
    expect(
      result.exitCode,
      0,
      reason:
          'Audit script exited non-zero. stderr:\n${result.stderr}\n'
          'stdout:\n${result.stdout}',
    );
    final stdout = result.stdout.toString();
    expect(stdout, contains('# Catalog diesel-gap audit (#1396)'));
    expect(stdout, contains('## Already covered'));
    // The Dacia Duster diesel sibling lands with this PR — assert it
    // is in the "Already covered" section so the script's join logic
    // is verified end-to-end against the catalog asset.
    expect(stdout, contains('Dacia | Duster'));
  });
}
