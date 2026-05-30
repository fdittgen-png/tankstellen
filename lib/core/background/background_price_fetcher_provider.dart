// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'android_background_price_fetcher.dart';
import 'background_price_fetcher.dart';
import 'ios_background_price_fetcher.dart';
import 'noop_background_price_fetcher.dart';

/// Creates the platform-appropriate [BackgroundPriceFetcher] implementation.
///
/// This is the cross-platform seam (CLAUDE.md rule #2): the only place that
/// branches on platform. Shared code (the coordinator, the callback) never
/// inlines a `Platform.is*` check — it talks to [BackgroundPriceFetcher].
///
/// - Android: [AndroidBackgroundPriceFetcher] (WorkManager)
/// - iOS: [IosBackgroundPriceFetcher] (workmanager iOS backend / BGAppRefresh)
/// - Other platforms (desktop/web test hosts): [NoopBackgroundPriceFetcher]
BackgroundPriceFetcher createBackgroundPriceFetcher() {
  if (Platform.isAndroid) {
    return AndroidBackgroundPriceFetcher();
  }
  if (Platform.isIOS) {
    return IosBackgroundPriceFetcher();
  }
  // Desktop / other test hosts: nothing to schedule.
  return NoopBackgroundPriceFetcher();
}
