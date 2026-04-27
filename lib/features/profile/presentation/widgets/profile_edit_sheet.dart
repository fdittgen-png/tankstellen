import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/country/country_config.dart';
import '../../../../core/language/language_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../vehicle/domain/entities/vehicle_profile.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../domain/entities/user_profile.dart';
import '../../providers/profile_edit_provider.dart';
import 'country_change_dialog.dart';
import 'profile_fuel_type_dropdown.dart';
import 'profile_landing_screen_dropdown.dart';
import 'profile_radius_slider.dart';

part 'profile_edit_sheet_parts.dart';
part 'profile_edit_sheet_parts2.dart';

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
              // Fuel preference is EITHER derived from the default vehicle
              // OR picked directly. The dropdown is disabled when a
              // vehicle is selected, removing the conflict shown in
              // image #7 (#695).
              Opacity(
                opacity: editState.defaultVehicleId != null ? 0.5 : 1.0,
                child: IgnorePointer(
                  ignoring: editState.defaultVehicleId != null,
                  child: ProfileFuelTypeDropdown(
                    value: editState.fuelType,
                    onChanged: editCtrl.setFuelType,
                  ),
                ),
              ),
              if (editState.defaultVehicleId != null) ...[
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)?.profileFuelFromVehicleHint ??
                      'Fuel type is derived from your default vehicle. '
                          'Clear the vehicle to pick a fuel directly.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
              const SizedBox(height: 16),
              ProfileRadiusSlider(
                value: editState.radius,
                onChanged: editCtrl.setRadius,
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
              _DefaultVehicleSection(state: editState, ctrl: editCtrl),
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
