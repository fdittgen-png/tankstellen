// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'profile_edit_sheet.dart';

/// Route-planning preferences — route-segment spacing, the maximum
/// detour budget (#1602) and the minimum-saving filter (#1872). The
/// whole section is gated on `Feature.routePlanning` by the caller, so
/// it is only built when the "along the route" search mode is
/// reachable.
class _RouteSegmentSection extends StatelessWidget {
  final ProfileEditState state;
  final ProfileEditController ctrl;

  const _RouteSegmentSection({required this.state, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('${l10n.routeSegment}:'),
            Expanded(
              child: Slider(
                value: state.routeSegmentKm,
                min: 50,
                max: 1000,
                divisions: 19,
                label: '${state.routeSegmentKm.round()} km',
                onChanged: ctrl.setRouteSegmentKm,
              ),
            ),
            Text('${state.routeSegmentKm.round()} km'),
          ],
        ),
        Text(
          l10n.showCheapestEveryNKm(state.routeSegmentKm.round()),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Row(
          children: [
            Text('${l10n.routeDetourBudget}:'),
            Expanded(
              child: Slider(
                value: state.routeDetourBudgetKm,
                min: 2,
                max: 25,
                divisions: 23,
                label: '${state.routeDetourBudgetKm.round()} km',
                onChanged: ctrl.setRouteDetourBudgetKm,
              ),
            ),
            Text('${state.routeDetourBudgetKm.round()} km'),
          ],
        ),
        Text(
          l10n.routeDetourBudgetCaption(state.routeDetourBudgetKm.round()),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        _buildMinSavingRow(context, theme, l10n),
      ],
    );
  }

  /// Minimum-saving slider (#1872). `0.0` is shown as "Off" — every
  /// station along the route is surfaced; a positive value keeps only
  /// stations priced within that band of the route's cheapest.
  Widget _buildMinSavingRow(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final saving = state.minRouteSavingPerLiter;
    final off = saving <= 0;
    // i18n-ignore: language-neutral currency-per-litre unit mask.
    final amount = '${saving.toStringAsFixed(2)} €/L';
    final valueLabel = off ? (l10n.routeMinSavingOff) : amount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('${l10n.routeMinSaving}:'),
            Expanded(
              child: Slider(
                value: saving,
                max: 0.30,
                divisions: 30,
                label: valueLabel,
                onChanged: ctrl.setMinRouteSavingPerLiter,
              ),
            ),
            Text(valueLabel),
          ],
        ),
        Text(
          off
              ? (l10n.routeMinSavingOffCaption)
              : (l10n.routeMinSavingCaption(amount)),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Three toggles: avoid highways, show fuel stations, show EV stations.
///
/// As of #1373 phase 3c the show-fuel and show-electric switches no
/// longer route through [ProfileEditController]. They read+write the
/// central feature-flag shim providers directly so a flip is
/// immediately visible to consumers (search results, map markers)
/// without waiting for the Save button. This mirrors the gamification
/// settings tile precedent (#1373 phase 3b). The avoid-highways
/// toggle stays on the local edit state because it persists on
/// `UserProfile`.
class _TogglesSection extends ConsumerWidget {
  final ProfileEditState state;
  final ProfileEditController ctrl;

  const _TogglesSection({required this.state, required this.ctrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final showFuel = ref.watch(showFuelEnabledProvider);
    final showElectric = ref.watch(showElectricEnabledProvider);
    return Column(
      children: [
        SwitchListTile(
          value: state.avoidHighways,
          onChanged: ctrl.setAvoidHighways,
          title: Text(l10n.avoidHighways),
          subtitle: Text(l10n.avoidHighwaysDesc),
          dense: true,
        ),
        SwitchListTile(
          value: showFuel,
          onChanged: (v) {
            unawaited(ref.read(showFuelEnabledProvider.notifier).set(v));
          },
          title: Text(l10n.showFuelStations),
          subtitle: Text(l10n.showFuelStationsDesc),
          dense: true,
        ),
        SwitchListTile(
          value: showElectric,
          onChanged: (v) {
            unawaited(ref.read(showElectricEnabledProvider.notifier).set(v));
          },
          title: Text(l10n.showEvStations),
          subtitle: Text(l10n.showEvStationsDesc),
          dense: true,
        ),
      ],
    );
  }
}

/// Segmented button for rating sharing mode plus a live description below.
class _RatingModeSection extends StatelessWidget {
  final ProfileEditState state;
  final ProfileEditController ctrl;

  const _RatingModeSection({required this.state, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<String>(
          segments: [
            ButtonSegment(
              value: 'local',
              label: Text(l10n.ratingModeLocal),
              icon: const Icon(Icons.phone_android, size: 16),
            ),
            ButtonSegment(
              value: 'private',
              label: Text(l10n.ratingModePrivate),
              icon: const Icon(Icons.lock, size: 16),
            ),
            ButtonSegment(
              value: 'shared',
              label: Text(l10n.ratingModeShared),
              icon: const Icon(Icons.people, size: 16),
            ),
          ],
          selected: {state.ratingMode},
          onSelectionChanged: (s) => ctrl.setRatingMode(s.first),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          state.ratingMode == 'local'
              ? (l10n.ratingDescLocal)
              : state.ratingMode == 'private'
              ? (l10n.ratingDescPrivate)
              : (l10n.ratingDescShared),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Dropdown to pick the default [VehicleProfile] used when the user opens
/// the Add fill-up form (#694). Null means "no vehicle pre-selected" —
/// the feature remains fully optional.
class _DefaultVehicleSection extends ConsumerWidget {
  final ProfileEditState state;
  final ProfileEditController ctrl;

  const _DefaultVehicleSection({required this.state, required this.ctrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final vehicles = ref.watch(vehicleProfileListProvider);
    if (vehicles.isEmpty) {
      // Nothing to pick from — hide the section entirely.
      return const SizedBox.shrink();
    }
    return DropdownButtonFormField<String?>(
      initialValue: vehicles.any((v) => v.id == state.defaultVehicleId)
          ? state.defaultVehicleId
          : null,
      decoration: InputDecoration(
        labelText: l10n.profileDefaultVehicleLabel,
        prefixIcon: const Icon(Icons.directions_car_outlined),
      ),
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text(l10n.profileDefaultVehicleNone),
        ),
        ...vehicles.map(
          (v) => DropdownMenuItem<String?>(value: v.id, child: Text(v.name)),
        ),
      ],
      onChanged: (v) {
        ctrl.setDefaultVehicleId(v);
        // When a vehicle is picked, sync the profile's fuel type to
        // that vehicle's fuel so the search/consumption pickers have
        // a single consistent source of truth (#695).
        if (v != null) {
          final vehicle = vehicles.firstWhere((x) => x.id == v);
          final derived = _vehicleFuelType(vehicle);
          if (derived != null) ctrl.setFuelType(derived);
        }
      },
    );
  }

  /// EV → electric; combustion → parsed preferredFuelType; null if not set.
  FuelType? _vehicleFuelType(VehicleProfile v) {
    if (v.type == VehicleType.ev) return FuelType.electric;
    final raw = v.preferredFuelType;
    if (raw == null || raw.trim().isEmpty) return null;
    return FuelType.fromString(raw);
  }
}

/// Save button (always shown) plus optional Delete button side-by-side.
class _SaveDeleteActions extends StatelessWidget {
  final ProfileEditState state;
  final UserProfile profile;
  final TextEditingController nameController;
  final TextEditingController zipController;
  final Future<void> Function(UserProfile) onSave;
  final VoidCallback? onDelete;
  final VoidCallback onConfirmDelete;

  const _SaveDeleteActions({
    required this.state,
    required this.profile,
    required this.nameController,
    required this.zipController,
    required this.onSave,
    required this.onDelete,
    required this.onConfirmDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: () async {
              // showFuel / showElectric are intentionally NOT included
              // in this copyWith — as of #1373 phase 3c they live in
              // the central feature-flag set, not on UserProfile. The
              // legacy bool fields stay populated on the saved
              // profile (carrying their previous value) so the
              // legacy-toggle migrator can still read them on a
              // downgrade-then-reupgrade path; the central flag is
              // the authoritative source.
              final updated = profile.copyWith(
                name: nameController.text.trim(),
                preferredFuelType: state.fuelType,
                defaultSearchRadius: state.radius,
                landingScreen: state.landingScreen,
                homeZipCode: zipController.text.trim().isEmpty
                    ? null
                    : zipController.text.trim(),
                countryCode: state.countryCode,
                languageCode: state.languageCode,
                routeSegmentKm: state.routeSegmentKm,
                routeDetourBudgetKm: state.routeDetourBudgetKm,
                minRouteSavingPerLiter: state.minRouteSavingPerLiter,
                avoidHighways: state.avoidHighways,
                ratingMode: state.ratingMode,
                defaultVehicleId: state.defaultVehicleId,
                approachRadiusKm: state.approachRadiusKm,
                approachPriceMode: state.approachPriceMode,
                approachMinPollSeconds: state.approachMinPollSeconds,
                routeSearchTopNPerSamplePoint:
                    state.routeSearchTopNPerSamplePoint,
                routeSearchCriterion: state.routeSearchCriterion,
              );
              await onSave(updated);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(l10n.save),
          ),
        ),
        if (onDelete != null) ...[
          const SizedBox(width: 16),
          OutlinedButton(
            onPressed: onConfirmDelete,
            style: OutlinedButton.styleFrom(
              foregroundColor: DarkModeColors.error(context),
            ),
            child: Text(l10n.delete),
          ),
        ],
      ],
    );
  }
}
