// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The explicit vehicle switch (#4213, Epic #4211).
///
/// A bottom sheet, not a screen — it has no app bar and never a
/// `Scaffold` (`no_raw_appbar_in_features_test`), because switching the
/// company car must cost one tap from whatever surface the driver is
/// on.
///
/// Recent-first, searchable by fleet code, model or registration
/// fragment, the current vehicle badged. It offers ONLY the vehicles an
/// assignment makes valid right now: a car handed over this morning is
/// gone from the list, and an expired offline directory shows the
/// reason instead of a list at all (ADR 0025 D4). Nothing in here can
/// be triggered by an adapter, a VIN or a GPS fix.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/fleet_vehicle.dart';
import '../../providers/current_fleet_vehicle_provider.dart';

/// Bottom sheet that lets the driver pick one of their assigned fleet
/// vehicles.
class VehicleSwitchSheet extends ConsumerStatefulWidget {
  const VehicleSwitchSheet({super.key});

  /// Opens the sheet; resolves to the picked fleet vehicle id, or null
  /// when the driver dismissed it without switching.
  static Future<String?> show(BuildContext context) =>
      showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => const VehicleSwitchSheet(),
      );

  @override
  ConsumerState<VehicleSwitchSheet> createState() => _VehicleSwitchSheetState();
}

class _VehicleSwitchSheetState extends ConsumerState<VehicleSwitchSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(currentFleetVehicleProvider);
    final matches = [
      for (final v in state.selectable)
        if (v.matches(_query)) v,
    ];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Spacing.xl, Spacing.xl, Spacing.xl, Spacing.md),
              child: Text(
                l10n.fleetVehicleSwitchTitle,
                style: AppText.title(context),
              ),
            ),
            _Notice(
              text: state.switchingEnabled
                  ? (state.isStale
                      ? l10n.fleetVehicleStaleNotice
                      : l10n.fleetVehicleSwitchHelper)
                  : l10n.fleetVehicleExpiredNotice,
              emphasised: !state.switchingEnabled,
            ),
            if (state.switchingEnabled) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    Spacing.xl, Spacing.md, Spacing.xl, Spacing.md),
                child: TextField(
                  key: const Key('fleet_vehicle_switch_search'),
                  autofocus: false,
                  decoration: InputDecoration(
                    labelText: l10n.fleetVehicleSearchLabel,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.md,
                    ),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              if (matches.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(Spacing.xl),
                  child: EmptyState(
                    icon: Icons.search_off,
                    title: l10n.fleetVehicleSearchEmpty,
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: matches.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: Spacing.xxl),
                    itemBuilder: (context, index) => _VehicleTile(
                      vehicle: matches[index],
                      isCurrent: matches[index].fleetVehicleId ==
                          state.vehicle?.fleetVehicleId,
                      onTap: () => _switchTo(matches[index]),
                    ),
                  ),
                ),
            ],
            const SizedBox(height: Spacing.md),
          ],
        ),
      ),
    );
  }

  /// The one path that changes the current vehicle: a tap.
  Future<void> _switchTo(FleetVehicle vehicle) async {
    final navigator = Navigator.of(context);
    final switched = await ref
        .read(currentFleetVehicleProvider.notifier)
        .select(vehicle.fleetVehicleId);
    if (!mounted) return;
    navigator.pop(switched ? vehicle.fleetVehicleId : null);
  }
}

/// The sheet's one explanatory line — the switch-never-rewrites-history
/// rule, the stale-copy caveat, or the expired-directory block.
class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.emphasised});

  final String text;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      key: const Key('fleet_vehicle_switch_notice'),
      padding: const EdgeInsets.fromLTRB(Spacing.xl, 0, Spacing.xl, 0),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: emphasised
              ? theme.colorScheme.error
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// One assigned vehicle: code + model, masked plate, current badge.
class _VehicleTile extends StatelessWidget {
  const _VehicleTile({
    required this.vehicle,
    required this.isCurrent,
    required this.onTap,
  });

  final FleetVehicle vehicle;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final plate = vehicle.plateMasked;
    return ListTile(
      key: Key('fleet_vehicle_tile_${vehicle.fleetVehicleId}'),
      leading: const Icon(Icons.directions_car),
      title: Text(
        vehicle.fleetCode,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        plate == null || plate.isEmpty
            ? vehicle.displayName
            : '${vehicle.displayName} · $plate',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isCurrent
          ? Chip(
              key: const Key('fleet_vehicle_current_badge'),
              label: Text(
                l10n.fleetVehicleCurrentBadge,
                style: theme.textTheme.labelSmall,
              ),
            )
          : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
