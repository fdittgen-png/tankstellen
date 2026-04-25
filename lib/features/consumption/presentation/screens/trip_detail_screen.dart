import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/feedback/auto_record_badge_provider.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../vehicle/domain/entities/vehicle_profile.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../data/trip_history_repository.dart';
import '../../domain/trip_recorder.dart';
import '../../providers/trip_history_provider.dart';
import '../widgets/trip_detail_body.dart';
import '../widgets/trip_detail_charts.dart';
import '../widgets/trip_detail_share_payload.dart';

// Re-export the visible-for-testing share payload builder so existing
// importers (and tests) can keep using the screen file as the entry
// point even though the implementation now lives in a sibling widget.
export '../widgets/trip_detail_share_payload.dart'
    show buildTripDetailSharePayload;

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
/// * **Share** copies a JSON summary + CSV sample block to the
///   clipboard so the user can paste it into a support ticket / diff
///   tool without needing any backend.
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final trips = ref.watch(tripHistoryListProvider);
    final entry = trips.where((t) => t.id == widget.tripId).firstOrNull;
    _maybeDecrementBadge(entry);
    final activeVehicle = ref.watch(activeVehicleProfileProvider);
    final vehicles = ref.watch(vehicleProfileListProvider);

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
        : (entry?.samples.map(_toDetailSample).toList(growable: false) ??
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
              IconButton(
                key: const Key('trip_detail_share_button'),
                icon: const Icon(Icons.share),
                tooltip: l?.trajetDetailShareAction ?? 'Share',
                onPressed: () => _onShare(context, l, entry, vehicle),
              ),
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
            ),
    );
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
      } catch (e) {
        debugPrint('TripDetailScreen badge decrement: $e');
      }
    });
  }

  Future<void> _onShare(
    BuildContext context,
    AppLocalizations? l,
    TripHistoryEntry entry,
    VehicleProfile? vehicle,
  ) async {
    final shareSamples = widget.samples.isNotEmpty
        ? widget.samples
        : entry.samples.map(_toDetailSample).toList(growable: false);
    final payload = tripDetailSharePayload(
      entry: entry,
      vehicle: vehicle,
      samples: shareSamples,
    );
    await Clipboard.setData(ClipboardData(text: payload));
    if (!context.mounted) return;
    final msg = l?.trajetDetailShareCopied ?? 'Copied to clipboard';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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

/// Convert a domain-layer [TripSample] (persisted on
/// [TripHistoryEntry]) into the presentation-layer [TripDetailSample]
/// the trip-detail charts consume (#1040). The two types carry the
/// same fields but live in different layers — keeping the converter
/// at the screen boundary stops the chart widgets from depending on
/// the consumption-domain package.
TripDetailSample _toDetailSample(TripSample s) => TripDetailSample(
      timestamp: s.timestamp,
      speedKmh: s.speedKmh,
      rpm: s.rpm,
      fuelRateLPerHour: s.fuelRateLPerHour,
    );
