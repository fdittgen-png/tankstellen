import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/country/country_config.dart';
import '../../../../core/language/language_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../domain/entities/user_profile.dart';
import '../../providers/profile_edit_provider.dart';
import 'profile_landing_screen_dropdown.dart';

/// Profile edit bottom sheet. Form state (fuel, radius, rating mode, etc.)
/// lives in [profileEditControllerProvider] so changes trigger selective
/// rebuilds and survive ephemeral widget rebuilds. Text values for name and
/// zip code remain in local [TextEditingController]s because controllers must
/// follow the Flutter widget lifecycle.
class ProfileEditSheet extends ConsumerStatefulWidget {
  final UserProfile profile;
  final Future<void> Function(UserProfile) onSave;
  final VoidCallback? onDelete;

  const ProfileEditSheet({
    super.key,
    required this.profile,
    required this.onSave,
    this.onDelete,
  });

  @override
  ConsumerState<ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends ConsumerState<ProfileEditSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _zipController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _zipController = TextEditingController(
      text: widget.profile.homeZipCode ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(BuildContext ctx) async {
    final l10n = AppLocalizations.of(ctx);
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(context).colorScheme.error,
          size: 48,
        ),
        title: Text(l10n?.deleteProfileTitle ?? 'Delete profile?'),
        content: Text(
          l10n?.deleteProfileBody ??
              'This profile and its settings will be permanently deleted. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n?.deleteProfileConfirm ?? 'Delete profile'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!ctx.mounted) return;
    widget.onDelete!();
    Navigator.pop(ctx);
  }

  @override
  Widget build(BuildContext context) {
    final editState = ref.watch(profileEditControllerProvider(widget.profile));
    final editCtrl =
        ref.read(profileEditControllerProvider(widget.profile).notifier);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                AppLocalizations.of(context)?.editProfile ?? 'Edit profile',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText:
                      AppLocalizations.of(context)?.profileName ?? 'Profile name',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<FuelType>(
                initialValue: editState.fuelType,
                decoration: InputDecoration(
                  labelText:
                      AppLocalizations.of(context)?.preferredFuel ?? 'Preferred fuel',
                  border: const OutlineInputBorder(),
                ),
                items: FuelType.values
                    .where((t) => t != FuelType.all)
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.displayName),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) editCtrl.setFuelType(v);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                      '${AppLocalizations.of(context)?.defaultRadius ?? "Radius"}:'),
                  Expanded(
                    child: Slider(
                      value: editState.radius,
                      min: 1,
                      max: 25,
                      divisions: 24,
                      label: '${editState.radius.round()} km',
                      onChanged: editCtrl.setRadius,
                    ),
                  ),
                  Text('${editState.radius.round()} km'),
                ],
              ),
              const SizedBox(height: 16),
              _RouteSegmentSection(state: editState, ctrl: editCtrl),
              _TogglesSection(state: editState, ctrl: editCtrl),
              const SizedBox(height: 16),
              _RatingModeSection(state: editState, ctrl: editCtrl),
              const SizedBox(height: 16),
              ProfileLandingScreenDropdown(
                value: editState.landingScreen,
                onChanged: editCtrl.setLandingScreen,
              ),
              const SizedBox(height: 16),
              _CountrySection(state: editState, ctrl: editCtrl),
              const SizedBox(height: 16),
              _LanguageSection(state: editState, ctrl: editCtrl),
              const SizedBox(height: 16),
              TextField(
                controller: _zipController,
                keyboardType: TextInputType.number,
                maxLength: editState.countryCode != null
                    ? (Countries.byCode(editState.countryCode!)?.postalCodeLength ?? 5)
                    : 5,
                decoration: InputDecoration(
                  labelText:
                      AppLocalizations.of(context)?.homeZip ?? 'Home postal code',
                  border: const OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 24),
              _SaveDeleteActions(
                state: editState,
                profile: widget.profile,
                nameController: _nameController,
                zipController: _zipController,
                onSave: widget.onSave,
                onDelete: widget.onDelete,
                onConfirmDelete: () => _confirmDelete(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

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

/// Country selector rendered as a wrap of ChoiceChips with flag + name.
class _CountrySection extends StatelessWidget {
  final ProfileEditState state;
  final ProfileEditController ctrl;

  const _CountrySection({required this.state, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.profileCountry ?? 'Country',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: Countries.all.map((c) {
            return ChoiceChip(
              label: Text('${c.flag} ${c.name}'),
              selected: c.code == state.countryCode,
              onSelected: (_) => ctrl.setCountryCode(c.code),
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Language selector rendered as a wrap of ChoiceChips with native names.
class _LanguageSection extends StatelessWidget {
  final ProfileEditState state;
  final ProfileEditController ctrl;

  const _LanguageSection({required this.state, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.profileLanguage ?? 'Language',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: AppLanguages.all.map((l) {
            return ChoiceChip(
              label: Text(l.nativeName),
              selected: l.code == state.languageCode,
              onSelected: (_) => ctrl.setLanguageCode(l.code),
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
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
