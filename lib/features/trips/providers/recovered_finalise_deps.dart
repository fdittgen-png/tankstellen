// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/feedback/auto_record_badge_provider.dart';
import '../../../core/feedback/auto_record_badge_service.dart';
import '../../../core/logging/app_log.dart';
import '../../../core/logging/error_logger.dart';
import '../data/trip_history_repository.dart';
import 'trip_history_provider.dart';

/// What the #1347 recovered-snapshot finalisation writes through.
typedef RecoveredFinaliseDeps = ({
  TripHistoryRepository? historyRepo,
  TripHistoryList? historyList,
  Future<AutoRecordBadgeService>? badge,
});

/// Resolve every Riverpod-backed dependency of the recovered finalise
/// synchronously up front.
///
/// Reading `ref` after an `await` is unsafe — the provider could be
/// disposed by then (rare in production thanks to `keepAlive: true`,
/// frequent in tests where the container goes out of scope before the
/// unawaited future settles). Each read is fenced on its own: a widget
/// test without the vehicle/badge graph simply finalises with less.
/// [automatic] gates the badge read — a manual trip never bumps it.
RecoveredFinaliseDeps recoveredFinaliseDeps(Ref ref,
    {required bool automatic}) {
  TripHistoryRepository? historyRepo;
  TripHistoryList? historyList;
  Future<AutoRecordBadgeService>? badge;
  try {
    historyRepo = ref.read(tripHistoryRepositoryProvider);
  } catch (e, st) {
    log.error(e, st, layer: ErrorLayer.providers, context: const {'where': 'TripRecording recovered finalise: history repo read failed'});
  }
  try {
    historyList = ref.read(tripHistoryListProvider.notifier);
  } catch (e, st) {
    log.error(e, st, layer: ErrorLayer.providers, context: const {'where': 'TripRecording recovered finalise: history list read failed'});
  }
  if (automatic) {
    try {
      badge = ref.read(autoRecordBadgeServiceProvider.future);
    } catch (e, st) {
      log.error(e, st, layer: ErrorLayer.providers, context: const {'where': 'TripRecording recovered finalise: badge service read failed'});
    }
  }
  return (historyRepo: historyRepo, historyList: historyList, badge: badge);
}
