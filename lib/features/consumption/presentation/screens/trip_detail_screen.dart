// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/feedback/auto_record_badge_provider.dart';
import '../../../../core/sharing/widget_share_renderer.dart';
import '../../../../core/sync/trip_shares_sync_enabled_provider.dart';
import '../../../../core/sync/trips_sync.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../vehicle/domain/entities/vehicle_profile.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../data/trip_history_repository.dart';
import '../../providers/shared_trips_provider.dart';
import '../../providers/trip_history_provider.dart';
import '../widgets/trip_detail_body.dart';
import '../widgets/trip_detail_charts.dart';
import '../widgets/trip_share_sheet.dart';
import 'trip_detail_downloads.dart';
import 'trip_detail_gpx_share.dart';
import 'trip_detail_sample_converter.dart';
import '../../../../core/logging/error_logger.dart';

/// Test-only override for the lazy fetcher (#1541 phase 4). Lets the
/// trip-detail widget test inject a fake fetch result without spinning
/// up a Supabase client.
@visibleForTesting
Future<Map<String, dynamic>?> Function(String tripId)?
    debugTripDetailFetchDetailsOverride;

/// Test-only override for the trip-detail Share renderer (#1189).
///
/// When set, the trip detail screen routes its Share action through
/// this function instead of [shareWidgetAsImage]. Lets widget tests
/// assert on the share invocation without driving the offscreen
/// rasterisation pipeline (which the fake-async clock can't resolve).
@visibleForTesting
Future<void> Function({
  required GlobalKey boundaryKey,
  required String subject,
  required String fileNameStem,
})? debugTripDetailShareOverride;

/// Trip detail screen (#890).
///
/// Renders a recorded trip's headline summary card plus the full
/// recording profile (speed / fuel-rate / RPM over time) as scrollable
/// [CustomPaint] line charts — mirroring the chart pattern shipped by
/// #582's charging charts.
///
/// ## Data flow
/// * [TripHistoryEntry] is read from [tripHistoryListProvider] keyed
///   by the path id. A missing entry (stale deep link) falls back to
///   a friendly empty-state instead of crashing the route.
/// * The per-sample time series ships in two ways:
///   1. The constructor's [samples] arg lets tests / future callers
///      inject a hand-built profile directly.
///   2. When [samples] is empty, the screen derives the chart input
///      from [TripHistoryEntry.samples] (#1040) — so any trip recorded
///      with the OBD2 buffer renders its full speed / fuel-rate / RPM
///      profile. Legacy entries written before #1040 carry an empty
///      list; the charts then fall back to the shared
///      "No samples recorded" empty-state caption.
///
/// ## AppBar actions
/// * **Share** rasterises the visible report (Summary card + Insights
///   cards + charts) into a PNG via a [RepaintBoundary] and hands it
///   to the OS share sheet through `share_plus` (#1189). The share
///   intent carries a localised subject ("Tankstellen — trip on
///   {date}") so messaging apps render a clean preview.
/// * **Delete** confirms and then calls
///   [TripHistoryList.delete] before popping back to the Trajets tab.
class TripDetailScreen extends ConsumerStatefulWidget {
  final String tripId;

  /// Optional per-sample profile used to populate the charts (#890).
  ///
  /// Defaults to an empty list — the production route relies on the
  /// per-trip samples persisted on [TripHistoryEntry.samples] (#1040)
  /// instead. Tests inject a non-empty list here to drive the chart
  /// CustomPaint path without needing Hive.
  final List<TripDetailSample> samples;

  const TripDetailScreen({
    super.key,
    required this.tripId,
    this.samples = const [],
  });

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen> {
  /// Latches the badge-decrement to the first frame after the trip
  /// detail mounts, so a `setState` rebuild can't trigger a second
  /// decrement and over-clear the launcher counter.
  bool _badgeDecremented = false;

  /// Latches the lazy-fetch for `trip_details` (#1541 phase 4) so a
  /// rebuild can't trigger a second round-trip — the fetch either
  /// succeeds and saves a fuller entry, or fails and there's nothing
  /// to retry within this screen lifecycle.
  bool _detailsHydrationAttempted = false;

  /// [GlobalKey] for the [RepaintBoundary] wrapping the report content
  /// — passed down to [TripDetailBody] so the Share action (#1189) can
  /// rasterise the report into a PNG.
  final GlobalKey _shareBoundaryKey = GlobalKey(
    debugLabel: 'trip_detail_share_boundary',
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final trips = ref.watch(tripHistoryListProvider);
    final ownedEntry = trips.where((t) => t.id == widget.tripId).firstOrNull;
    // #2240 — a trip shared WITH the user isn't in their local Hive
    // history; fall back to the live "shared with me" list so tapping a
    // shared row opens a read-only detail. `isShared` gates the owner-
    // only actions (cross-account share / delete) off for these.
    final sharedTrips = ref.watch(sharedTripsProvider).value ?? const [];
    final isShared = ownedEntry == null;
    final entry = ownedEntry ??
        sharedTrips.where((t) => t.id == widget.tripId).firstOrNull;
    _maybeDecrementBadge(entry);
    if (!isShared) _maybeHydrateDetails(entry);
    final activeVehicle = ref.watch(activeVehicleProfileProvider);
    final vehicles = ref.watch(vehicleProfileListProvider);
    // Cross-account sharing (#2240) — only offered when trip sync is
    // enabled (email-backed account ∧ cloudSync ∧ syncTrips), since a
    // trip can only be shared once it's actually synced to the server.
    // Never offered for a trip that was shared WITH you (you're not the
    // owner) — re-sharing / deleting someone else's trip isn't allowed.
    final canShareCrossAccount =
        !isShared && ref.watch(tripSharesSyncEnabledProvider);

    // Resolve the per-trip vehicle so the summary card can show the
    // friendly name. Fall back to the active vehicle when the trip
    // pre-dates the vehicleId tagging from #889.
    final vehicle = entry?.vehicleId == null
        ? activeVehicle
        : vehicles.where((v) => v.id == entry!.vehicleId).firstOrNull ??
            activeVehicle;
    final isEv = vehicle?.type == VehicleType.ev;

    // Production callers pass widget.samples = const [] so the screen
    // pulls the per-trip profile straight off the persisted entry
    // (#1040). Tests pre-populate widget.samples; honour that input
    // instead of overriding it. Legacy entries with no samples render
    // the shared empty-state caption — same UX as a fresh install.
    final List<TripDetailSample> samples = widget.samples.isNotEmpty
        ? widget.samples
        : (entry?.samples.map(toDetailSample).toList(growable: false) ??
            const []);

    return PageScaffold(
      title: l?.tripHistoryTitle ?? 'Trip history',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: l?.tooltipBack ?? 'Back',
        onPressed: () => context.pop(),
      ),
      actions: entry == null
          ? null
          : [
              PopupMenuButton<String>(
                key: const Key('trip_detail_share_menu'),
                icon: const Icon(Icons.share),
                tooltip: l?.trajetDetailShareAction ?? 'Share',
                onSelected: (value) {
                  switch (value) {
                    case 'image':
                      unawaited(_onShare(context, l, entry, vehicle));
                    case 'gpx':
                      unawaited(shareTripGpx(context, l, entry));
                    case 'download_csv':
                      unawaited(downloadTripCsv(context, l, entry));
                    case 'download_json':
                      unawaited(downloadTripJson(context, l, entry));
                    case 'cross_account':
                      unawaited(showTripShareSheet(context, entry.id));
                  }
                },
                itemBuilder: (_) => buildTripDetailShareMenuItems(
                  l,
                  entry,
                  showCrossAccount: canShareCrossAccount,
                ),
              ),
              // Delete mutates the local Hive history — meaningless for
              // a trip shared WITH you (you don't own it). Hidden for
              // shared trips (#2240); revocation is the owner's job.
              if (!isShared)
                IconButton(
                  key: const Key('trip_detail_delete_button'),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l?.trajetDetailDeleteAction ?? 'Delete',
                  onPressed: () => _onDelete(context, ref, l),
                ),
            ],
      bodyPadding: EdgeInsets.zero,
      body: entry == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l?.tripHistoryEmptyTitle ?? 'No trips yet',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : TripDetailBody(
              entry: entry,
              vehicle: vehicle,
              samples: samples,
              isEv: isEv,
              shareBoundaryKey: _shareBoundaryKey,
            ),
    );
  }

  /// Lazy-fetch the heavy `samples` + `gpsd` blob from `trip_details`
  /// when the local Hive entry is summary-only (#1541 phase 4). Fires
  /// at most once per screen mount. The most common trigger: an entry
  /// that arrived via the app-launch [TripsSync.merge] pass — the
  /// summary downloaded fine but the details stayed on the server.
  void _maybeHydrateDetails(TripHistoryEntry? entry) {
    if (_detailsHydrationAttempted) return;
    if (entry == null) return;
    if (entry.samples.isNotEmpty ||
        entry.gpsSampleDiagnostics.isNotEmpty) {
      // Already hydrated locally — either the trip was recorded on
      // this device or a previous mount already downloaded the
      // details. Nothing to do.
      return;
    }
    _detailsHydrationAttempted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final fetcher = debugTripDetailFetchDetailsOverride ??
            TripsSync.fetchDetails;
        final data = await fetcher(entry.id);
        if (data == null) return;
        // Round-trip the merged JSON through fromJson so the
        // sample / diagnostic decoders stay the single source of
        // truth for the wire shape — no parallel decode path to
        // keep in sync.
        final merged = {...entry.toJson(), ...data};
        final hydrated = TripHistoryEntry.fromJson(merged);
        if (!mounted) return;
        await ref.read(tripHistoryListProvider.notifier).save(hydrated);
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {'where': 'TripDetailScreen lazy-fetch'}));
      }
    });
  }

  /// Decrement the launcher-icon badge once on the first build that
  /// resolves an auto-recorded entry (#1004 phase 5). Scheduled
  /// post-frame so we don't mutate provider state during a build.
  void _maybeDecrementBadge(TripHistoryEntry? entry) {
    if (_badgeDecremented) return;
    if (entry == null || !entry.automatic) return;
    _badgeDecremented = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final badge =
            await ref.read(autoRecordBadgeServiceProvider.future);
        await badge.decrement();
        // Phase 6: also refresh the reactive count so the
        // trip-history "Mark all as read" badge updates without
        // waiting for a route change.
        await ref.read(autoRecordBadgeCountProvider.notifier).refresh();
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {'where': 'TripDetailScreen badge decrement'}));
      }
    });
  }

  Future<void> _onShare(
    BuildContext context,
    AppLocalizations? l,
    TripHistoryEntry entry,
    VehicleProfile? vehicle,
  ) async {
    // Compose a friendly subject line so the OS share sheet (and the
    // receiving app's preview) shows "Tankstellen — trip on <date>"
    // instead of a bare filename.
    final locale = Localizations.localeOf(context);
    final shareDate = entry.summary.startedAt ?? DateTime.now();
    final formattedDate =
        DateFormat.yMMMd(locale.toString()).format(shareDate);
    final subject = l?.trajetDetailShareSubject(formattedDate) ??
        'Sparkilo — trip on $formattedDate';
    final messenger = ScaffoldMessenger.maybeOf(context);
    final scheme = Theme.of(context).colorScheme;
    final renderer = debugTripDetailShareOverride ?? shareWidgetAsImage;
    try {
      await renderer(
        boundaryKey: _shareBoundaryKey,
        subject: subject,
        fileNameStem: 'tankstellen_trip_${entry.id}',
      );
    } catch (e, st) {
      // Surface the failure to the user instead of silently swallowing
      // it — the snackbar tells them the share didn't go through, and
      // the debugPrint keeps the cause in `flutter logs` for support.
      unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {'where': 'TripDetailScreen share image'}));
      if (messenger == null) return;
      final errorMsg = l?.trajetDetailShareError ??
          "Couldn't generate share image";
      messenger.showSnackBar(SnackBarHelper.errorSnackBar(scheme, errorMsg));
    }
  }

  Future<void> _onDelete(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations? l,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l?.trajetDetailDeleteConfirmTitle ?? 'Delete this trip?',
        ),
        content: Text(
          l?.trajetDetailDeleteConfirmBody ??
              'This trip will be permanently removed from your history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l?.trajetDetailDeleteConfirmCancel ?? 'Cancel',
            ),
          ),
          TextButton(
            key: const Key('trip_detail_delete_confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l?.trajetDetailDeleteConfirmConfirm ?? 'Delete',
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(tripHistoryListProvider.notifier).delete(widget.tripId);
    if (!context.mounted) return;
    context.pop();
  }
}

