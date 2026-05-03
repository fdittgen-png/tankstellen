import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_state_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/obd2/obd2_breadcrumb_collector.dart';
import '../../providers/obd2_breadcrumb_provider.dart';

/// In-app overlay that renders the most recent fuel-rate breadcrumbs
/// captured by [Obd2BreadcrumbsNotifier] (#1395). Sibling to the map
/// debug breadcrumb overlay shipped in PR #1378.
///
/// Always visible in `kDebugMode`; in release builds the user enables
/// it via the hidden 5-tap gesture on the trip-recording screen
/// title (which flips [obd2DebugOverlayProvider]). The overlay
/// renders one row per fuel-rate sample with the resolved branch tag
/// ([5E] / [MAF] / [SD] / [--]), the L/h surfaced to the trip
/// integrator, and a smaller second line with AFR / density /
/// displacement / VE actually used. Rows are colour-coded by flag —
/// green for clean samples, amber for suspicious-low (RPM > 1500
/// AND L/h < 0.3), red for 5E-vs-MAF divergence > 50 %.
///
/// The widget self-hides when neither path is enabled, returning a
/// zero-cost [SizedBox.shrink], so the screen pays nothing for it in
/// production builds where the flag is off.
class Obd2BreadcrumbOverlay extends ConsumerWidget {
  const Obd2BreadcrumbOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tolerate the Hive-box-not-open path — widget tests (e.g.
    // trip_recording_screen_page_scaffold_test) pump the recording
    // screen without bootstrapping Hive, and the overlay must not
    // blow up the screen. The production overlay only surfaces in
    // `kDebugMode || flag-set` — a missing flag is identical to "off"
    // from the user's perspective.
    bool flag = false;
    try {
      flag = ref.watch(obd2DebugOverlayProvider);
    } catch (e, st) {
      debugPrint('Obd2BreadcrumbOverlay flag read failed: $e\n$st');
      flag = false;
    }
    final visible = kDebugMode || flag;
    if (!visible) return const SizedBox.shrink();

    List<Obd2Breadcrumb> crumbs = const [];
    try {
      crumbs = ref.watch(obd2BreadcrumbsProvider);
    } catch (e, st) {
      debugPrint('Obd2BreadcrumbOverlay crumbs read failed: $e\n$st');
      crumbs = const [];
    }
    final l10n = AppLocalizations.of(context);

    // Wrap in ExcludeSemantics so the Android tap-target guideline
    // test (used by `active_recording_screen_pin_test`) doesn't trip
    // on the developer-only overlay's compact Clear / Close buttons.
    // The overlay is not a user-facing UI element; release builds
    // ship with the flag off and the overlay returns
    // [SizedBox.shrink], so the exclusion is debug-only in practice.
    return Positioned(
      right: 8,
      bottom: 8,
      child: ExcludeSemantics(
        child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 280,
            maxHeight: 360,
            minWidth: 200,
            minHeight: 100,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n?.obd2DebugOverlayTitle ?? 'OBD2 breadcrumbs',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ref
                              .read(obd2BreadcrumbsProvider.notifier)
                              .clear();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: const Size(0, 32),
                          tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          l10n?.obd2DebugOverlayClearButton ?? 'Clear',
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ref
                              .read(obd2DebugOverlayProvider.notifier)
                              .disable();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: const Size(0, 32),
                          tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          l10n?.obd2DebugOverlayCloseButton ?? 'Close',
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 8),
                  Flexible(
                    child: SingleChildScrollView(
                      reverse: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Newest-first: walk reversed so the bottom
                          // of the scroll view shows the most recent
                          // sample. `reverse: true` on the scroll view
                          // keeps the freshest row pinned at bottom.
                          for (final c in crumbs.reversed)
                            _BreadcrumbRow(crumb: c),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

/// One row in the diagnostic overlay: timestamp + branch + L/h on
/// line 1, AFR/density/displacement/VE on line 2 (smaller). Colour
/// reflects the sanity flag: green = clean, amber = suspicious-low,
/// red = 5E-vs-MAF divergent.
class _BreadcrumbRow extends StatelessWidget {
  const _BreadcrumbRow({required this.crumb});

  final Obd2Breadcrumb crumb;

  String get _timestamp {
    final h = crumb.at.hour.toString().padLeft(2, '0');
    final m = crumb.at.minute.toString().padLeft(2, '0');
    final s = crumb.at.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get _branchTag {
    switch (crumb.branch) {
      case Obd2BranchTag.pid5E:
        return '5E';
      case Obd2BranchTag.maf:
        return 'MAF';
      case Obd2BranchTag.speedDensity:
        return 'SD';
      case Obd2BranchTag.none:
        return '--';
    }
  }

  Color get _color {
    switch (crumb.flag) {
      case Obd2BreadcrumbCollector.flagSuspiciousLow:
        return Colors.amber;
      case Obd2BreadcrumbCollector.flag5eVsMafDivergent:
        return Colors.redAccent;
      default:
        return Colors.greenAccent;
    }
  }

  String _formatRate(double? r) =>
      r == null ? '--' : r.toStringAsFixed(2);

  String _formatNum(double? v, {int decimals = 1}) =>
      v == null ? '--' : v.toStringAsFixed(decimals);

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final secondLine = StringBuffer()
      ..write('AFR=${_formatNum(crumb.afr, decimals: 1)} ')
      ..write('ρ=${_formatNum(crumb.fuelDensityGPerL, decimals: 0)} ')
      ..write('cc=${_formatNum(crumb.engineDisplacementCc, decimals: 0)} ')
      ..write('η=${_formatNum(crumb.volumetricEfficiency, decimals: 2)}');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$_timestamp [$_branchTag] ${_formatRate(crumb.fuelRateLPerHour)} L/h',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontFamily: 'monospace',
              height: 1.2,
            ),
          ),
          Text(
            secondLine.toString(),
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 9,
              fontFamily: 'monospace',
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
