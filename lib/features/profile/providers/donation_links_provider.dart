// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Platform-dispatch seam for the About-section donation links (#3536).
///
/// App Review guideline 3.1.1 forbids donation mechanisms other than
/// In-App Purchase, so the external PayPal / Revolut links must not
/// render on iOS. Android (Play + F-Droid) keeps them. This provider is
/// a sanctioned `defaultTargetPlatform` seam (see
/// `test/lint/no_inline_platform_check_test.dart`) so the About widget
/// stays free of inline platform branching; widget tests override it.
final donationLinksVisibleProvider = Provider<bool>(
  (ref) => defaultTargetPlatform != TargetPlatform.iOS,
);
