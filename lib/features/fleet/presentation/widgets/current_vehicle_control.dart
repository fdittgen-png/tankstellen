// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// The quiet "current vehicle" context chip (#4213, #4218).
///
/// Deliberately a **chip, not a screen**: #4218 declined a fleet tab
/// regroup, so the employee's vehicle context rides along on the fuel,
/// drive, fill-up and expense surfaces as one compact control that says
/// which car the next entry will be attributed to, and opens
/// [VehicleSwitchSheet] on tap.
///
/// Four states, never collapsed:
///
///   * a vehicle, switchable;
///   * a vehicle from an offline copy of the directory — badged, still
///     switchable while the copy is under 7 days old;
///   * a vehicle the driver may not switch away from right now
///     (expired directory) — rendered disabled **with its reason**,
///     never hidden and never silently swapped (ADR 0025 D4);
///   * **needs confirmation** — the caller resolved its signals and the
///     adapter/VIN/QR disagreed. The chip says so and keeps naming the
///     current vehicle; nothing is attributed automatically until the
///     driver picks (#4213). The caller passes the [proposal]; this
///     widget never listens to a signal source itself, which is what
///     makes "no auto-switch" structural rather than a promise.
///
/// A personal (non-fleet) user gets nothing at all.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/fleet_vehicle.dart';
import '../../domain/vehicle_attribution_resolver.dart';
import '../../providers/current_fleet_vehicle_provider.dart';
import 'vehicle_switch_sheet.dart';

/// Compact context chip naming the current fleet vehicle.
class CurrentVehicleControl extends ConsumerWidget {
  const CurrentVehicleControl({super.key, this.proposal});

  /// What the caller's signals resolved to, when it has any. Only
  /// [VehicleAttributionVerdict.needsConfirmation] changes what is
  /// rendered — a confirmed proposal is the caller's to act on (by
  /// stamping the record it creates), never this chip's to act on.
  final VehicleAttributionResolution? proposal;

  /// `VAN-12 · VW Caddy` — the fleet code first, because that is what
  /// an employee reads off the key fob.
  static String describe(FleetVehicle vehicle) =>
      '${vehicle.fleetCode} · ${vehicle.displayName}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(currentFleetVehicleProvider);
    if (!state.isVisible) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final vehicle = state.vehicle;
    final unconfirmed = proposal?.needsConfirmation ?? false;
    final label = unconfirmed
        ? l10n.fleetVehicleNeedsConfirmationTitle
        : vehicle == null
            ? l10n.fleetVehicleNoneAssigned
            : describe(vehicle);
    final enabled = state.switchingEnabled;

    return Semantics(
      button: enabled,
      enabled: enabled,
      label: l10n.fleetVehicleSemanticsCurrent(label),
      hint: enabled ? l10n.fleetVehicleSemanticsChange : null,
      child: Tooltip(
        message: unconfirmed
            ? l10n.fleetVehicleNeedsConfirmationBody
            : enabled
                ? l10n.fleetVehicleSemanticsChange
                : l10n.fleetVehicleExpiredNotice,
        child: InkWell(
          key: const Key('fleet_current_vehicle_control'),
          borderRadius: AppRadius.md,
          onTap: enabled ? () => VehicleSwitchSheet.show(context) : null,
          child: Container(
            padding: Spacing.chipPadding,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: AppRadius.md,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  unconfirmed
                      ? Icons.help_outline
                      : enabled
                          ? Icons.directions_car
                          : Icons.cloud_off,
                  size: 18,
                  color: unconfirmed
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: Spacing.md),
                // ExcludeSemantics: the Semantics wrapper above already
                // announces the label; the raw text would double it.
                Flexible(
                  child: ExcludeSemantics(
                    child: _ChipLabel(label: label, enabled: enabled),
                  ),
                ),
                if (state.isStale) ...[
                  const SizedBox(width: Spacing.md),
                  _StaleBadge(label: l10n.fleetVehicleStaleBadge),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The chip's two lines of text, collapsed to one when the caller is
/// tight — the label ellipsises rather than overflowing at 360 dp with
/// large text (#4076's rule for pills).
class _ChipLabel extends StatelessWidget {
  const _ChipLabel({required this.label, required this.enabled});

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final colour = enabled
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurfaceVariant;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.fleetVehicleCurrentLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge?.copyWith(color: colour),
        ),
      ],
    );
  }
}

/// "Offline copy" — the badge that keeps a stale directory honest.
class _StaleBadge extends StatelessWidget {
  const _StaleBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('fleet_current_vehicle_stale_badge'),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: AppRadius.sm,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall
            ?.copyWith(color: theme.colorScheme.onTertiaryContainer),
      ),
    );
  }
}
