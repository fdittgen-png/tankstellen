// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'profile_edit_sheet.dart';

/// The avoid-highways toggle plus a link to where station types live.
///
/// #3884 — the show-fuel / show-EV switches were a second home for the
/// central `showFuel` / `showElectric` feature flags (#1373 phase 3c)
/// that Features & use mode already owns; one home per parameter, so
/// this card links there instead. The avoid-highways toggle stays on the
/// local edit state because it persists on `UserProfile`.
class _TogglesSection extends StatelessWidget {
  final ProfileEditState state;
  final ProfileEditController ctrl;

  const _TogglesSection({required this.state, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        SwitchListTile(
          value: state.avoidHighways,
          onChanged: ctrl.setAvoidHighways,
          title: Text(l10n.avoidHighways),
          subtitle: Text(l10n.avoidHighwaysDesc),
          dense: true,
        ),
        ListTile(
          key: const Key('profileStationTypesLink'),
          leading: const Icon(Icons.dashboard_customize_outlined),
          title: Text(l10n.settingsStationTypesLink),
          trailing: const Icon(Icons.chevron_right),
          dense: true,
          onTap: () => context.push(RoutePaths.settingsFeatures),
        ),
      ],
    );
  }
}

// The rating-mode segmented button moved to `rating_mode_section.dart`
// (public `RatingModeSection`, #3871) so the one-time public-contribution
// notice that gates the switch to "shared" is testable in isolation.

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
    final selectedId = vehicles.any((v) => v.id == state.defaultVehicleId)
        ? state.defaultVehicleId
        : null;
    final selected = selectedId == null
        ? null
        : vehicles.firstWhere((v) => v.id == selectedId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String?>(
          initialValue: selectedId,
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
              (v) =>
                  DropdownMenuItem<String?>(value: v.id, child: Text(v.name)),
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
        ),
        // #706 / #3884 — a hybrid runs on two fuels; which one drives the
        // price search is the profile's `hybridFuelChoice`. Only shown
        // for a multi-fuel default vehicle; null keeps the vehicle's own
        // combustion fuel (`effectiveFuelTypeProvider`).
        if (selected != null && selected.type == VehicleType.hybrid) ...[
          const SizedBox(height: Spacing.xl),
          _buildHybridFuelChoice(l10n, selected),
        ],
      ],
    );
  }

  Widget _buildHybridFuelChoice(AppLocalizations l10n, VehicleProfile v) {
    final fuels = <FuelType>[FuelType.electric, ?_combustionFuel(v)];
    final current = fuels.contains(state.hybridFuelChoice)
        ? state.hybridFuelChoice
        : null;
    return DropdownButtonFormField<FuelType?>(
      key: const Key('hybridFuelChoiceDropdown'),
      initialValue: current,
      decoration: InputDecoration(
        labelText: l10n.hybridFuelChoiceLabel,
        prefixIcon: const Icon(Icons.local_gas_station_outlined),
      ),
      items: [
        DropdownMenuItem<FuelType?>(
          value: null,
          child: Text(l10n.hybridFuelChoiceVehicleDefault),
        ),
        for (final f in fuels)
          DropdownMenuItem<FuelType?>(value: f, child: Text(f.displayName)),
      ],
      onChanged: ctrl.setHybridFuelChoice,
    );
  }

  /// The combustion side of a hybrid, or null when the vehicle carries
  /// no parseable fuel string.
  FuelType? _combustionFuel(VehicleProfile v) {
    final raw = v.preferredFuelType;
    if (raw == null || raw.trim().isEmpty) return null;
    final parsed = FuelType.fromString(raw);
    return parsed == FuelType.electric ? null : parsed;
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
                hybridFuelChoice: state.hybridFuelChoice,
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
