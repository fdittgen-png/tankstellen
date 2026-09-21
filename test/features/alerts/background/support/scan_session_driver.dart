// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:tankstellen/core/domain/data_value.dart';
import 'package:tankstellen/core/notifications/notification_delivery.dart';
import 'package:tankstellen/core/notifications/notification_service.dart';
import 'package:tankstellen/core/services/provider_capability.dart';
import 'package:tankstellen/features/alerts/background/background_scan_body.dart';
import 'package:tankstellen/features/alerts/background/notification_templates.dart';
import 'package:tankstellen/features/alerts/background/opportunity_dispatcher.dart';
import 'package:tankstellen/features/alerts/background/scan_opportunity_dispatch.dart';
import 'package:tankstellen/features/alerts/domain/opportunity.dart';

/// The pinned instant every lifecycle suite starts at — a mid-month
/// Wednesday, mid-morning UTC.
final DateTime kScanT0 = DateTime.utc(2026, 9, 16, 9);

/// A favourite-station opportunity worth a notification.
Opportunity scanOpportunity({
  required DateTime at,
  String stationId = 'de-aral-1',
  String fuelType = 'e10',
}) =>
    Opportunity(
      kind: OpportunityKind.favouriteStation,
      stationId: stationId,
      stationName: 'ARAL Berlin',
      fuelType: fuelType,
      currentPrice: 1.649,
      reference: OpportunityReference.thresholdYouSet,
      referencePrice: 1.729,
      grossSaving: 4.2,
      detourCost: 0.4,
      netSaving: 3.8,
      distanceKm: 3.2,
      priceAge: const DataValue.measured(Duration(minutes: 12)),
      confidence: DataConfidence.high,
      detectedAt: at,
      expiresAt: at.add(const Duration(hours: 6)),
    );

/// A [ScanBody] whose stages a test scripts, and whose dispatch stage runs
/// the REAL [OpportunityDispatcher] — budget, feed and all — against the
/// real alerts box, so a delivery claim is checked against real stores.
class ScriptedScanBody implements ScanBody {
  ScriptedScanBody(
    this.at, {
    this.candidates = const [],
    this.park,
    this.throwIn,
    this.stations = 1,
  });

  final DateTime at;

  /// What the detectors "found" this scan.
  final List<Opportunity> candidates;

  /// When set, [collect] waits for it — an iOS expiry or a WorkManager stop
  /// is a run that never gets past this.
  final Park? park;

  /// The stage that throws, if any: 'collect', 'dispatch' or 'widgets'.
  final String? throwIn;

  /// Stations "fetched"; zero takes the empty-set path.
  final int stations;

  final List<String> stages = [];

  @override
  Future<void> collect() async {
    stages.add('collect');
    final park = this.park;
    if (park != null) {
      park._reached.complete();
      await park.future;
    }
    if (throwIn == 'collect') throw StateError('collect failed');
  }

  @override
  bool get isEmpty => stations == 0;

  @override
  int get stationsScanned => stations;

  @override
  Future<ScanDispatchResult> dispatch(
      Future<NotificationService> Function() notifier) async {
    stages.add('dispatch');
    if (throwIn == 'dispatch') throw StateError('dispatch failed');
    final outcome = await const OpportunityDispatcher().dispatch(
      candidates: [for (final o in candidates) OpportunityCandidate(o)],
      now: at,
      notifier: await notifier(),
      templates: BackgroundNotificationTemplates.resolveForLanguage('en'),
    );
    final delivery = outcome.delivery;
    return (
      alertsFired: outcome.notified ? 1 : 0,
      undelivered: delivery == null || delivery.wasPosted ? null : delivery,
    );
  }

  @override
  Future<void> refreshWidgets() async {
    stages.add('widgets');
    if (throwIn == 'widgets') throw StateError('widget refresh failed');
  }
}

/// A completer-backed park: [future] until [release].
class Park {
  final Completer<void> _c = Completer<void>();
  final Completer<void> _reached = Completer<void>();
  Future<void> get future => _c.future;

  /// Completes when a run has arrived at the park.
  Future<void> get reached => _reached.future;
  void release() {
    if (!_c.isCompleted) _c.complete();
  }
}
