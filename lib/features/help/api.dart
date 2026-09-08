// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Public API barrel of the `help` feature (#4007).
///
/// Cross-feature consumers must import THIS file — never a path under
/// `providers/` or `presentation/`. Enforced by
/// `test/lint/feature_boundary_test.dart`.
///
/// The `?` symbol itself is deliberately **not** here: `HelpDot` lives
/// in `core/help/` because every feature places one, and a widget every
/// feature needs is core rather than someone else's public API.
library;

export 'presentation/screens/help_screen.dart' show HelpScreen;
export 'providers/help_providers.dart'
    show helpAnchorAssetFor, helpAssetFor, helpLocales;
