// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Platform-resolved onboarding step composition (#3163).
///
/// The onboarding wizard used to branch on `defaultTargetPlatform`
/// inline in shared presentation code — a hole in the plugin-pattern
/// lint guard (`test/lint/no_inline_platform_check_test.dart`), which
/// only matched `Platform.isXxx`. This provider is the sanctioned
/// dispatch seam: it resolves whether the iOS-only standby explainer
/// step (#1542 phase 6) is part of the wizard, so the screen itself
/// stays platform-agnostic.
///
/// Widget tests either override this provider or set
/// `debugDefaultTargetPlatformOverride` before the wizard's first
/// build (the existing tests do the latter; the provider reads the
/// platform lazily on first access within each test's fresh
/// `ProviderScope`, so both seams keep working).
final onboardingIncludesIosStandbyStepProvider = Provider<bool>(
  (ref) => defaultTargetPlatform == TargetPlatform.iOS,
);
