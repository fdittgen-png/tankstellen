// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../data/obd2/broken_map_belief.dart';
import '../../providers/consumption_providers.dart';

/// Confidence band thresholds shared by every broken-MAP UI surface
/// (#1423 phase 5; #1424 reuses against the Bayesian
/// [BrokenMapBelief.pointEstimate]). Mirrors the table in the
/// issue spec § E:
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

/// Bands for [BrokenMapBelief.pointEstimate]. Computed once per build
/// so the widgets read a single enum instead of re-comparing floats.
enum BrokenMapBand { silent, verifying, warning, hardDisable }

/// Map a raw [BrokenMapBelief.pointEstimate] to a band. Pure helper —
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
    if (brokenMapBandFor(belief.pointEstimate) != BrokenMapBand.hardDisable) {
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
    if (brokenMapBandFor(belief.pointEstimate) != BrokenMapBand.warning) {
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
/// #1423 phase 5; #1424 deliverable G). Renders the active vehicle's
/// posterior point estimate and the half-width of the 95 % credible
/// interval, formatted as a percentage:
///
///   - silent (<0.4)        -> "MAP sensor: 5% ± 8%"   (green; or
///                              "MAP sensor: 5% ± 8% (verified)" once
///                              the auto-clear gate has fired)
///   - verifying (0.4-0.7)  -> "MAP sensor: 43% ± 12%" (amber)
///   - warning (0.7-0.9)    -> "MAP sensor: 75% ± 7%"  (red)
///   - hardDisable (>=0.9)  -> "MAP sensor: 92% ± 4%"  (red)
///
/// The CI half-width is `(upper - lower) / 2` — the same shape Bayesian
/// reporting traditionally uses for a single-number margin. The
/// (verified) badge is only added in the silent band, when
/// [BrokenMapBelief.isVerifiedClean] is true.
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
    final pe = belief.pointEstimate;
    final band = brokenMapBandFor(pe);
    final ci = belief.credibleInterval;
    final pePct = (pe * 100).toStringAsFixed(0);
    final marginPct = ((ci.$2 - ci.$1) / 2 * 100).toStringAsFixed(0);
    final String text;
    final Color color;
    switch (band) {
      case BrokenMapBand.silent:
        // Silent band gets a "verified" badge appended when the
        // auto-clear gate has fired (50+ obs, mean<0.1, upper-CI<0.3).
        // Otherwise it's still informative ("MAP sensor: 5% ± 8%")
        // because observationCount > 0 means we DO want to show the
        // user the live posterior rather than hide it entirely.
        if (belief.isVerifiedClean) {
          text = l?.brokenMapOverlayPosteriorVerified(pePct, marginPct) ??
              'MAP sensor: $pePct% ± $marginPct% (verified)';
        } else {
          text = l?.brokenMapOverlayPosterior(pePct, marginPct) ??
              'MAP sensor: $pePct% ± $marginPct%';
        }
        color = DarkModeColors.success(context);
        break;
      case BrokenMapBand.verifying:
        text = l?.brokenMapOverlayPosterior(pePct, marginPct) ??
            'MAP sensor: $pePct% ± $marginPct%';
        color = DarkModeColors.warning(context);
        break;
      case BrokenMapBand.warning:
      case BrokenMapBand.hardDisable:
        text = l?.brokenMapOverlayPosterior(pePct, marginPct) ??
            'MAP sensor: $pePct% ± $marginPct%';
        color = DarkModeColors.error(context);
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

/// Diagnostics card surfacing the active vehicle's broken-MAP belief
/// and the persistent per-adapter [ObdAdapterBlocklist], with a manual
/// "Clear" escape hatch (#1622).
///
/// Without this card a user whose healthy adapter got mis-flagged has
/// no way to undo the blocklist entry — the VIN populator keeps
/// short-circuiting future pair attempts with a stale warning recalled
/// from the blocklist.
///
/// The belief shown is for [vehicleId] (the vehicle the host screen is
/// about — read directly from [brokenMapBeliefByVehicleProvider] rather
/// than via the active-vehicle provider, to keep the card off the
/// vehicle-list provider graph); the blocklist is global. Collapses to
/// [SizedBox.shrink] when the vehicle has zero observations AND the
/// blocklist is empty — the common healthy case costs no layout.
class BrokenMapDiagnosticsCard extends ConsumerStatefulWidget {
  const BrokenMapDiagnosticsCard({super.key, this.vehicleId});

  /// The vehicle whose broken-MAP belief to display. Null → the belief
  /// section is omitted and only the global adapter blocklist shows.
  final String? vehicleId;

  @override
  ConsumerState<BrokenMapDiagnosticsCard> createState() =>
      _BrokenMapDiagnosticsCardState();
}

class _BrokenMapDiagnosticsCardState
    extends ConsumerState<BrokenMapDiagnosticsCard> {
  Future<Map<String, double>>? _entries;

  @override
  void initState() {
    super.initState();
    _entries = ref.read(obdAdapterBlocklistProvider).entries();
  }

  Future<void> _clear(String elmId) async {
    await ref.read(obdAdapterBlocklistProvider).clearEntry(elmId);
    if (!mounted) return;
    setState(() {
      _entries = ref.read(obdAdapterBlocklistProvider).entries();
    });
  }

  /// The broken-MAP belief for [BrokenMapDiagnosticsCard.vehicleId],
  /// read directly off [brokenMapBeliefByVehicleProvider]. Returns null
  /// when no vehicle id was supplied or the lookup throws (Hive may not
  /// be open in widget tests) — defensive, the card is decorative.
  BrokenMapBelief? _belief() {
    final id = widget.vehicleId;
    if (id == null || id.isEmpty) return null;
    try {
      // Watch the state so the card rebuilds when the belief map flips.
      ref.watch(brokenMapBeliefByVehicleProvider);
      return ref
          .read(brokenMapBeliefByVehicleProvider.notifier)
          .beliefFor(id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final belief = _belief();
    final hasBelief = belief != null && belief.observationCount > 0;
    return FutureBuilder<Map<String, double>>(
      future: _entries,
      builder: (context, snap) {
        final blocklist = snap.data ?? const <String, double>{};
        // Nothing observed, nothing blocklisted → render nothing.
        if (!hasBelief && blocklist.isEmpty) {
          return const SizedBox.shrink();
        }
        final l = AppLocalizations.of(context);
        final theme = Theme.of(context);
        return SectionCard(
          title: l?.brokenMapDiagnosticsCardTitle ?? 'MAP sensor diagnostics',
          leadingIcon: Icons.sensors,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _beliefSection(l, theme, belief, hasBelief),
              const SizedBox(height: 12),
              Text(
                l?.brokenMapDiagnosticsBlocklistHeading ??
                    'Blocklisted adapters',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              if (blocklist.isEmpty)
                Text(
                  l?.brokenMapDiagnosticsBlocklistEmpty ??
                      'No adapters are blocklisted.',
                  style: theme.textTheme.bodyMedium,
                )
              else
                ...blocklist.entries.map(
                  (e) => _BlocklistRow(
                    elmId: e.key,
                    confidence: e.value,
                    onClear: () => _clear(e.key),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _beliefSection(AppLocalizations? l, ThemeData theme,
      BrokenMapBelief? belief, bool hasBelief) {
    if (!hasBelief) {
      return Text(
        l?.brokenMapDiagnosticsBeliefNone ??
            "This vehicle's MAP sensor hasn't been observed yet.",
        style: theme.textTheme.bodyMedium,
      );
    }
    final pe = belief!.pointEstimate;
    final ci = belief.credibleInterval;
    final pePct = (pe * 100).toStringAsFixed(0);
    final marginPct = ((ci.$2 - ci.$1) / 2 * 100).toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l?.brokenMapDiagnosticsBeliefLine(pePct, marginPct) ??
              'Broken-MAP confidence: $pePct% ± $marginPct%',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 2),
        Text(
          l?.brokenMapDiagnosticsObservationCount(belief.observationCount) ??
              '${belief.observationCount} observations recorded',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (belief.isVerifiedClean) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.verified_outlined,
                  size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                l?.brokenMapDiagnosticsVerifiedBadge ?? 'Verified clean',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// One blocklisted-adapter row inside [BrokenMapDiagnosticsCard]: the
/// adapter's ELM firmware id, its recorded broken-confidence, and a
/// "Clear" button that removes it from the blocklist.
class _BlocklistRow extends StatelessWidget {
  const _BlocklistRow({
    required this.elmId,
    required this.confidence,
    required this.onClear,
  });

  final String elmId;
  final double confidence;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final pct = (confidence * 100).toStringAsFixed(0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l?.brokenMapDiagnosticsBlocklistEntry(elmId, pct) ??
                  '$elmId — flagged $pct% broken',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          TextButton(
            key: Key('brokenMapBlocklistClear_$elmId'),
            onPressed: onClear,
            child: Text(
              l?.brokenMapDiagnosticsClearButton ?? 'Clear',
            ),
          ),
        ],
      ),
    );
  }
}
