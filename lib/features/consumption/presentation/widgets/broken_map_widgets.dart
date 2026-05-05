import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../data/obd2/broken_map_belief.dart';
import '../../providers/consumption_providers.dart';

/// Confidence band thresholds shared by every broken-MAP UI surface
/// (#1423 phase 5). Mirrors the table in the issue spec § E:
///   - <0.4   silent
///   - 0.4-0.7 verifying chip / overlay row
///   - 0.7-0.9 disclaimer chip + snackbar
///   - >=0.9   hard-disable banner
///
/// Centralised so a future spec tweak only changes one place; the
/// numbers also match `brokenMapBlocklistThreshold` (0.7) so the per-
/// adapter persistence kicks in at the same crossing the snackbar does.
@visibleForTesting
const double brokenMapVerifyingThreshold = 0.4;
@visibleForTesting
const double brokenMapWarningThreshold = 0.7;
@visibleForTesting
const double brokenMapHardDisableThreshold = 0.9;

/// Bands for [BrokenMapBelief.confidence]. Computed once per build
/// so the widgets read a single enum instead of re-comparing floats.
enum BrokenMapBand { silent, verifying, warning, hardDisable }

/// Map a raw [BrokenMapBelief.confidence] to a band. Pure helper —
/// exposed so tests can assert the band thresholds without spinning
/// up a widget tree.
BrokenMapBand brokenMapBandFor(double confidence) {
  if (confidence >= brokenMapHardDisableThreshold) {
    return BrokenMapBand.hardDisable;
  }
  if (confidence >= brokenMapWarningThreshold) {
    return BrokenMapBand.warning;
  }
  if (confidence >= brokenMapVerifyingThreshold) {
    return BrokenMapBand.verifying;
  }
  return BrokenMapBand.silent;
}

/// Look up the active vehicle's belief, defaulting to a fresh
/// [BrokenMapBelief] when there is no active vehicle (or the lookup
/// throws — Hive may not be open in widget tests). Returns null when
/// the active vehicle has never been observed AND the active vehicle
/// is unknown — caller renders nothing in that case.
BrokenMapBelief? readActiveVehicleBelief(WidgetRef ref) {
  try {
    final active = ref.watch(activeVehicleProfileProvider);
    if (active == null) return null;
    // Watch the provider state (not the notifier) so the widget
    // rebuilds when [BrokenMapBeliefByVehicle.set] flips the cached
    // map. Watching `.notifier` only rebuilds on a notifier instance
    // swap and silently misses state mutations.
    ref.watch(brokenMapBeliefByVehicleProvider);
    return ref
        .read(brokenMapBeliefByVehicleProvider.notifier)
        .beliefFor(active.id);
  } catch (_) {
    // Defensive against the Hive-not-open / provider-not-wired path.
    // The diagnostic surfaces are decorative; their absence must not
    // break the host screen.
    return null;
  }
}

/// Persistent MaterialBanner shown at the top of the trip-recording
/// screen when the active vehicle's broken-MAP belief is at or above
/// the hard-disable threshold (#1423 phase 5). Tells the user the
/// live fuel-rate display has been turned off and the app is now
/// using receipt-derived L/100 km. Self-hides for any other band.
class BrokenMapBanner extends ConsumerWidget {
  const BrokenMapBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final belief = readActiveVehicleBelief(ref);
    if (belief == null) return const SizedBox.shrink();
    if (brokenMapBandFor(belief.confidence) != BrokenMapBand.hardDisable) {
      return const SizedBox.shrink();
    }
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return MaterialBanner(
      key: const Key('brokenMapBanner'),
      backgroundColor: theme.colorScheme.errorContainer,
      contentTextStyle: TextStyle(
        color: theme.colorScheme.onErrorContainer,
      ),
      leading: Icon(
        Icons.warning_amber_outlined,
        color: theme.colorScheme.onErrorContainer,
      ),
      content: Text(
        l?.brokenMapBannerHardDisable ??
            'MAP sensor unreliable. Showing fill-up averages instead of '
                'live fuel rate.',
      ),
      actions: const [SizedBox.shrink()],
    );
  }
}

/// Small chip rendered alongside the live fuel-rate metric while
/// the active vehicle's broken-MAP belief sits in the warning band
/// (0.7-0.9). The number stays visible — the chip just tells the
/// user it may be undercounting (#1423 phase 5).
class BrokenMapDisclaimerChip extends ConsumerWidget {
  const BrokenMapDisclaimerChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final belief = readActiveVehicleBelief(ref);
    if (belief == null) return const SizedBox.shrink();
    if (brokenMapBandFor(belief.confidence) != BrokenMapBand.warning) {
      return const SizedBox.shrink();
    }
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: Chip(
          key: const Key('brokenMapDisclaimerChip'),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: theme.colorScheme.errorContainer,
          labelStyle: TextStyle(
            color: theme.colorScheme.onErrorContainer,
            fontSize: 11,
          ),
          avatar: Icon(
            Icons.warning_amber_outlined,
            size: 14,
            color: theme.colorScheme.onErrorContainer,
          ),
          label: Text(
            l?.brokenMapChipDisclaimer ?? 'MAP readings suspicious',
          ),
        ),
      ),
    );
  }
}

/// Diagnostic row added to the OBD2 breadcrumb overlay (#1395 +
/// #1423 phase 5). Renders one of three localised lines based on the
/// active vehicle's belief band:
///   - silent (<0.4)        -> hidden (the row also hides when there
///                              is no observation yet — overlay would
///                              otherwise flash a "verified (0.00)"
///                              row for vehicles we've never probed)
///   - verifying (0.4-0.7)  -> "MAP sensor: verifying (0.43)"
///   - warning (0.7-0.9)    -> "MAP sensor: suspicious (0.75)"
///   - hardDisable (>=0.9)  -> "MAP sensor: suspicious (0.92)"
///
/// Defensive: returns [SizedBox.shrink] whenever the belief lookup
/// throws or the active vehicle has zero observations (i.e. has
/// never been probed) so the overlay doesn't flash a spurious row
/// before the first plein-complet reconciliation lands.
class BrokenMapOverlayRow extends ConsumerWidget {
  const BrokenMapOverlayRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final belief = readActiveVehicleBelief(ref);
    if (belief == null || belief.observationCount == 0) {
      return const SizedBox.shrink();
    }
    final l = AppLocalizations.of(context);
    final band = brokenMapBandFor(belief.confidence);
    final formatted = belief.confidence.toStringAsFixed(2);
    final String text;
    final Color color;
    switch (band) {
      case BrokenMapBand.silent:
      case BrokenMapBand.verifying:
        // Verified (silent) and verifying are both rendered with the
        // same "verified" string for confidence < 0.4, and the
        // "verifying" string for 0.4-0.7 — different copy keys, same
        // colour. The silent band is allowed through here because
        // observationCount > 0 means we DO want to show the user
        // "verified (0.05)" rather than nothing.
        if (band == BrokenMapBand.silent) {
          text = l?.brokenMapOverlayVerified(formatted) ??
              'MAP sensor: verified ($formatted)';
          color = Colors.greenAccent;
        } else {
          text = l?.brokenMapOverlayUnverified(formatted) ??
              'MAP sensor: verifying ($formatted)';
          color = Colors.amber;
        }
        break;
      case BrokenMapBand.warning:
      case BrokenMapBand.hardDisable:
        text = l?.brokenMapOverlaySuspicious(formatted) ??
            'MAP sensor: suspicious ($formatted)';
        color = Colors.redAccent;
        break;
    }
    return Padding(
      key: const Key('brokenMapOverlayRow'),
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontFamily: 'monospace',
          height: 1.2,
        ),
      ),
    );
  }
}
