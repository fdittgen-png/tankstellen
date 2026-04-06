import 'package:flutter/material.dart';
import '../../../../core/country/country_config.dart';
import '../../../../core/language/language_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../data/models/user_profile.dart';

class ProfileEditSheet extends StatefulWidget {
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
  State<ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<ProfileEditSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _zipController;
  late FuelType _fuelType;
  late double _radius;
  late LandingScreen _landingScreen;
  late String? _countryCode;
  late String? _languageCode;
  late double _routeSegmentKm;
  late bool _avoidHighways;
  late bool _showFuel;
  late bool _showElectric;
  late String _ratingMode;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _zipController = TextEditingController(
      text: widget.profile.homeZipCode ?? '',
    );
    _fuelType = widget.profile.preferredFuelType;
    _radius = widget.profile.defaultSearchRadius;
    _landingScreen = widget.profile.landingScreen;
    _countryCode = widget.profile.countryCode;
    _languageCode = widget.profile.languageCode;
    _routeSegmentKm = widget.profile.routeSegmentKm;
    _avoidHighways = widget.profile.avoidHighways;
    _showFuel = widget.profile.showFuel;
    _showElectric = widget.profile.showElectric;
    _ratingMode = widget.profile.ratingMode;
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

    if (confirmed == true && mounted) {
      widget.onDelete!();
      Navigator.pop(ctx);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                initialValue: _fuelType,
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
                onChanged: (v) => setState(() => _fuelType = v ?? _fuelType),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                      '${AppLocalizations.of(context)?.defaultRadius ?? "Radius"}:'),
                  Expanded(
                    child: Slider(
                      value: _radius,
                      min: 1,
                      max: 25,
                      divisions: 24,
                      label: '${_radius.round()} km',
                      onChanged: (v) => setState(() => _radius = v),
                    ),
                  ),
                  Text('${_radius.round()} km'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('${AppLocalizations.of(context)?.routeSegment ?? "Route segment"}:'),
                  Expanded(
                    child: Slider(
                      value: _routeSegmentKm,
                      min: 50,
                      max: 1000,
                      divisions: 19,
                      label: '${_routeSegmentKm.round()} km',
                      onChanged: (v) =>
                          setState(() => _routeSegmentKm = v),
                    ),
                  ),
                  Text('${_routeSegmentKm.round()} km'),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  AppLocalizations.of(context)?.showCheapestEveryNKm(_routeSegmentKm.round()) ?? 'Show cheapest station every ${_routeSegmentKm.round()} km along route',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              SwitchListTile(
                value: _avoidHighways,
                onChanged: (v) => setState(() => _avoidHighways = v),
                title: Text(AppLocalizations.of(context)?.avoidHighways ?? 'Avoid highways'),
                subtitle: Text(AppLocalizations.of(context)?.avoidHighwaysDesc ?? 'Route calculation avoids toll roads and highways'),
                dense: true,
              ),
              SwitchListTile(
                value: _showFuel,
                onChanged: (v) => setState(() => _showFuel = v),
                title: Text(AppLocalizations.of(context)?.showFuelStations ?? 'Show fuel stations'),
                subtitle: Text(AppLocalizations.of(context)?.showFuelStationsDesc ?? 'Include gas, diesel, LPG, CNG stations'),
                dense: true,
              ),
              SwitchListTile(
                value: _showElectric,
                onChanged: (v) => setState(() => _showElectric = v),
                title: Text(AppLocalizations.of(context)?.showEvStations ?? 'Show EV charging stations'),
                subtitle: Text(AppLocalizations.of(context)?.showEvStationsDesc ?? 'Include electric charging stations in search results'),
                dense: true,
              ),
              // Rating sharing mode
              const SizedBox(height: 16),
              Text('Station ratings', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'local', label: Text('Local'), icon: Icon(Icons.phone_android, size: 16)),
                  ButtonSegment(value: 'private', label: Text('Private'), icon: Icon(Icons.lock, size: 16)),
                  ButtonSegment(value: 'shared', label: Text('Shared'), icon: Icon(Icons.people, size: 16)),
                ],
                selected: {_ratingMode},
                onSelectionChanged: (s) => setState(() => _ratingMode = s.first),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 4),
                child: Text(
                  _ratingMode == 'local'
                      ? 'Ratings saved on this device only'
                      : _ratingMode == 'private'
                          ? 'Synced with your database (not visible to others)'
                          : 'Visible to all users of your database',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<LandingScreen>(
                initialValue: _landingScreen,
                decoration: InputDecoration(
                  labelText:
                      AppLocalizations.of(context)?.landingScreen ?? 'Start screen',
                  border: const OutlineInputBorder(),
                ),
                // Exclude 'map' from landing options — map is not a landing screen
                items: LandingScreen.values
                    .where((s) => s != LandingScreen.map)
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.localizedName(
                            Localizations.localeOf(context).languageCode,
                          )),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _landingScreen = v ?? _landingScreen),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)?.profileCountry ?? 'Country',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: Countries.all.map((c) {
                  return ChoiceChip(
                    label: Text('${c.flag} ${c.name}'),
                    selected: c.code == _countryCode,
                    onSelected: (_) => setState(() => _countryCode = c.code),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)?.profileLanguage ?? 'Language',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: AppLanguages.all.map((l) {
                  return ChoiceChip(
                    label: Text(l.nativeName),
                    selected: l.code == _languageCode,
                    onSelected: (_) =>
                        setState(() => _languageCode = l.code),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _zipController,
                keyboardType: TextInputType.number,
                maxLength: _countryCode != null
                    ? (Countries.byCode(_countryCode!)?.postalCodeLength ?? 5)
                    : 5,
                decoration: InputDecoration(
                  labelText:
                      AppLocalizations.of(context)?.homeZip ?? 'Home postal code',
                  border: const OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        final updated = widget.profile.copyWith(
                          name: _nameController.text.trim(),
                          preferredFuelType: _fuelType,
                          defaultSearchRadius: _radius,
                          landingScreen: _landingScreen,
                          homeZipCode: _zipController.text.trim().isEmpty
                              ? null
                              : _zipController.text.trim(),
                          countryCode: _countryCode,
                          languageCode: _languageCode,
                          routeSegmentKm: _routeSegmentKm,
                          avoidHighways: _avoidHighways,
                          showFuel: _showFuel,
                          showElectric: _showElectric,
                          ratingMode: _ratingMode,
                        );
                        await widget.onSave(updated);
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Text(AppLocalizations.of(context)?.save ?? 'Save'),
                    ),
                  ),
                  if (widget.onDelete != null) ...[
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: () => _confirmDelete(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child:
                        Text(AppLocalizations.of(context)?.delete ?? 'Delete'),
                  ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
