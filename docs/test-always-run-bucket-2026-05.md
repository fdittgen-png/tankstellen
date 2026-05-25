<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# Always-run test bucket — May 2026

**Issue**: #1593 (parent epic #1591 — path-affected test selection).

**Scope**: the subset of tests that run on **every** PR, regardless of
diff. These are tests that assert global invariants (lint contracts,
ADR format, ARB parity, security manifests) and don't transitively
import any `lib/` file.

**Why this matters**: the selector tool (#1592) automatically detects
this bucket — any test whose transitive import graph has zero overlap
with `lib/` is added to the always-run set unconditionally. There's no
human-maintained list. The doc below catalogues the bucket as of May
2026 so contributors know what's expected to stay cross-cutting.

## How the bucket is detected

`tool/test_selector.dart`:

```dart
for (final t in allTests) {
  final transitive = _transitiveClosure(t, imports);
  final libDeps = transitive.where((f) => f.startsWith('lib/')).toSet();

  if (libDeps.isEmpty) {
    // Cross-cutting: no transitive lib import → always-run bucket.
    alwaysRun.add(t);
    continue;
  }
  // ...
}
```

A test enters the bucket the moment its `_test.dart` file (and every
file it transitively imports) collectively has **zero** files under
`lib/`. Adding a `package:tankstellen/...` or relative `../lib/...`
import to one of these tests will move it out of the bucket.

## Convention for new tests

- **Lint / static-analysis tests** (`test/lint/*`): MUST stay in the
  always-run bucket. They walk `lib/` source via `dart:io`, not via
  imports, so the static check stays cross-cutting by construction.
  Don't introduce `import 'package:tankstellen/...'` into a lint test;
  re-read the file from disk instead.
- **Doc / ADR / metadata tests** (`test/docs/*`, `test/i18n/*`): same
  rule — scan files, don't import them.
- **Security manifests** (`test/security/*`): assert on
  `AndroidManifest.xml`, Info.plist, build.gradle.kts shape. Always-run.
- **CI workflow shape** (`test/ci/ci_workflow_test.dart`): reads
  `.github/workflows/ci.yml` from disk. Always-run.
- **Performance / startup contracts** (`test/core/perf/*`): assert on
  the instrumentation hook layout, not on `lib/` widget behaviour.
  Always-run.
- **Feature tests** (`test/features/<area>/*`): MUST import the
  feature's `lib/` code so they get scoped per-PR by path-affected
  selection. Don't add a feature test to the always-run bucket.

## Catalogue (May 2026 — 43 tests)

Run `dart run tool/test_selector.dart - <<< "README.md"` to dump the
current bucket; the list below is the snapshot taken at the time of
filing #1593.

### Lint / static-analysis (16)

- `test/lint/analysis_options_severity_test.dart`
- `test/lint/arb_fragments_consistency_test.dart`
- `test/lint/asset_spec_coverage_test.dart`
- `test/lint/catch_block_stacktrace_coverage_test.dart`
- `test/lint/declared_dependencies_test.dart`
- `test/lint/design_system_doc_present_test.dart`
- `test/lint/icon_button_tooltip_coverage_test.dart` *(also tagged accessibility)*
- `test/lint/no_hardcoded_ui_strings_test.dart`
- `test/lint/no_raw_appbar_in_features_test.dart`
- `test/lint/no_raw_card_in_features_test.dart`
- `test/lint/no_raw_debugprint_error_test.dart`
- `test/lint/no_silent_catch_test.dart`
- `test/lint/prefer_const_constructors_test.dart`
- `test/lint/retry_tile_provider_call_site_test.dart`

### Localisation (3)

- `test/i18n/arb_key_parity_test.dart`
- `test/l10n/localization_completeness_test.dart`
- *(ARB-fragments-consistency in lint counted above)*

### Documentation / ADR / privacy (4)

- `test/docs/adr_format_test.dart`
- `test/docs/new_country_guide_test.dart`
- `test/docs/privacy_policy_test.dart`
- `test/docs/storage_migration_eval_test.dart`

### Security manifests (5)

- `test/security/android_manifest_security_test.dart`
- `test/security/no_hardcoded_secrets_test.dart`
- `test/security/no_plaintext_station_endpoints_test.dart`
- `test/security/trip_sync_migration_test.dart`
- *(also: `test/lint/no_silent_catch_test.dart` arguably security)*

### App / startup / signing (3)

- `test/app/app_initializer_phase1_test.dart`
- `test/app/app_initializer_test.dart`
- `test/app/signing_config_test.dart`

### Core utilities (5)

- `test/core/perf/startup_instrumentation_test.dart`
- `test/core/services/api_connectivity_test.dart`
- `test/core/services/dio_factory_consolidation_test.dart`
- `test/core/services/error_recovery_pattern_test.dart`
- `test/core/services/germany_no_special_case_test.dart`
- `test/core/telemetry/glitchtip_compatibility_test.dart`
- `test/core/utils/navigation_utils_test.dart`

### Map lifecycle contracts (2)

- `test/features/map/presentation/map_controller_lifecycle_test.dart`
- `test/features/map/tile_layer_eviction_strategy_test.dart`

These test pure contract shapes (lifecycle ordering, eviction
strategy) without importing the map widget itself. Borderline — if a
contributor adds a `package:tankstellen/...` import here, they'll
leave the bucket and run only when map code changes. That's likely
fine but worth flagging.

### CI / tooling (3)

- `test/ci/ci_workflow_test.dart`
- `test/goldens/golden_directory_layout_test.dart`
- `test/tool/audit_catalog_diesel_gaps_test.dart`
- `test/tool/test_selector_test.dart`

## Regression test

`test/tool/always_run_bucket_test.dart` (filed in the same PR as this
doc) asserts that the **highest-value** always-run tests stay in the
bucket. The full list above is documentary; the regression test pins
only the load-bearing ones (lint contracts, ARB parity, ADR format,
security manifests) so an accidental `package:tankstellen` import in
one of them trips CI immediately rather than silently scoping the
test to a specific PR.

## What to do if a test moves out of the bucket

If you run the regression test and an asserted-cross-cutting test is
missing from the bucket:

1. **Check the imports** — did someone add `package:tankstellen/...`
   or a relative `../lib/...` path? Often the fix is "read the file
   from disk via `dart:io`" instead.
2. **Re-evaluate**: is the test still cross-cutting? Maybe it
   legitimately turned into a feature test and the regression
   assertion is the wrong contract.
3. **Update the doc** below + the regression test if the move is
   intentional.

The bucket itself is auto-detected — there's nothing to "register" a
new test as always-run. Write it without `lib/` imports and it lands
there automatically.
