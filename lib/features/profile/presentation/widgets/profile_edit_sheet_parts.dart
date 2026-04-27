part of 'profile_edit_sheet.dart';

/// Route-segment slider with a caption showing the km-between-stations value.
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
            Text('${l10n?.routeSegment ?? "Route segment"}:'),
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
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            l10n?.showCheapestEveryNKm(state.routeSegmentKm.round()) ??
                'Show cheapest station every ${state.routeSegmentKm.round()} km along route',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// Three toggles: avoid highways, show fuel stations, show EV stations.
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
          title: Text(l10n?.avoidHighways ?? 'Avoid highways'),
          subtitle: Text(l10n?.avoidHighwaysDesc ??
              'Route calculation avoids toll roads and highways'),
          dense: true,
        ),
        SwitchListTile(
          value: state.showFuel,
          onChanged: ctrl.setShowFuel,
          title: Text(l10n?.showFuelStations ?? 'Show fuel stations'),
          subtitle: Text(l10n?.showFuelStationsDesc ??
              'Include gas, diesel, LPG, CNG stations'),
          dense: true,
        ),
        SwitchListTile(
          value: state.showElectric,
          onChanged: ctrl.setShowElectric,
          title: Text(l10n?.showEvStations ?? 'Show EV charging stations'),
          subtitle: Text(l10n?.showEvStationsDesc ??
              'Include electric charging stations in search results'),
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
        Text(l10n?.privacyRatings ?? 'Station ratings',
            style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(
                value: 'local',
                label: Text(l10n?.ratingModeLocal ?? 'Local'),
                icon: const Icon(Icons.phone_android, size: 16)),
            ButtonSegment(
                value: 'private',
                label: Text(l10n?.ratingModePrivate ?? 'Private'),
                icon: const Icon(Icons.lock, size: 16)),
            ButtonSegment(
                value: 'shared',
                label: Text(l10n?.ratingModeShared ?? 'Shared'),
                icon: const Icon(Icons.people, size: 16)),
          ],
          selected: {state.ratingMode},
          onSelectionChanged: (s) => ctrl.setRatingMode(s.first),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 4),
          child: Text(
            state.ratingMode == 'local'
                ? (l10n?.ratingDescLocal ??
                    'Ratings saved on this device only')
                : state.ratingMode == 'private'
                    ? (l10n?.ratingDescPrivate ??
                        'Synced with your database (not visible to others)')
                    : (l10n?.ratingDescShared ??
                        'Visible to all users of your database'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
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
      initialValue:
          vehicles.any((v) => v.id == state.defaultVehicleId)
              ? state.defaultVehicleId
              : null,
      decoration: InputDecoration(
        labelText:
            l10n?.profileDefaultVehicleLabel ?? 'Default vehicle (optional)',
        prefixIcon: const Icon(Icons.directions_car_outlined),
      ),
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text(l10n?.profileDefaultVehicleNone ?? 'No default'),
        ),
        ...vehicles.map(
          (v) => DropdownMenuItem<String?>(
            value: v.id,
            child: Text(v.name),
          ),
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
                avoidHighways: state.avoidHighways,
                showFuel: state.showFuel,
                showElectric: state.showElectric,
                ratingMode: state.ratingMode,
                defaultVehicleId: state.defaultVehicleId,
              );
              await onSave(updated);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(l10n?.save ?? 'Save'),
          ),
        ),
        if (onDelete != null) ...[
          const SizedBox(width: 16),
          OutlinedButton(
            onPressed: onConfirmDelete,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(l10n?.delete ?? 'Delete'),
          ),
        ],
      ],
    );
  }
}
