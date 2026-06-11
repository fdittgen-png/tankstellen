// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import 'background_price_fetcher.dart';

/// No-op [BackgroundPriceFetcher] for platforms with no background-scan
/// backend (desktop / web / unit-test hosts). Android uses WorkManager and
/// iOS uses the workmanager BGTask backend; everything else falls back here
/// so [createBackgroundPriceFetcher] never returns null.
class NoopBackgroundPriceFetcher implements BackgroundPriceFetcher {
  @override
  Future<void> init() async {
    debugPrint(
        'BackgroundPriceFetcher: no background-scan backend on this platform');
  }

  @override
  Future<void> cancelAll() async {
    // Nothing to cancel.
  }

  @override
  Future<void> scheduleOpportunisticScan() async {
    // No background-scan backend — nothing to schedule (#3169).
  }
}
