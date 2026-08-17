// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/audit_catalog_diesel_gaps.dart' as audit;

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
///      "covered" row).
///
/// #3752 — the audit runs IN-PROCESS via [audit.runAudit] instead of
/// spawning `dart run`: the subprocess raced the concurrently-running
/// `flutter test` over `.dart_tool` (the Dart build-hooks resolver
/// died with "File not formatted as yaml"), turning the master
/// full-suite CI shard deterministically red while standalone runs
/// stayed green.
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

  test('audit runs in-process and emits the markdown header', () {
    final report = audit.runAudit();
    expect(report, isNotNull,
        reason: 'vehicles.json must exist when running from the repo root');
    expect(report, contains('# Catalog diesel-gap audit (#1396)'));
    expect(report, contains('## Already covered'));
    // The Dacia Duster diesel sibling ships in the catalog — assert it
    // is in the "Already covered" section so the script's join logic
    // is verified end-to-end against the catalog asset.
    expect(report, contains('Dacia | Duster'));
  });
}
