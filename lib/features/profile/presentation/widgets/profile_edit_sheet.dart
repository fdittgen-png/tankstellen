// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/country/country_config.dart';
import '../../../../core/language/language_provider.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../feature_management/application/feature_flags_provider.dart';
import '../../../feature_management/domain/feature.dart';
import '../../../feature_management/domain/feature_dependency_graph.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/vehicle_profile.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../domain/entities/user_profile.dart';
import '../../providers/profile_edit_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/show_electric_enabled_provider.dart';
import '../../providers/show_fuel_enabled_provider.dart';
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

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // #1602 — the route-planning preferences are only meaningful when
    // the "along the route" search mode is reachable, so the section
    // tracks `Feature.routePlanning` exactly as search_criteria_screen
    // gates the mode toggle.
    final routePlanningOn = isEffectivelyEnabled(
      Feature.routePlanning,
      ref.watch(featureManifestProvider),
      ref.watch(enabledFeaturesProvider),
    );

    // #2551 — render the whole Vehicle card only when there is at least
    // one vehicle to pick from (matching the prior section-level hide).
    final hasVehicles = ref.watch(vehicleProfileListProvider).isNotEmpty;

    final cards = <Widget>[
      // 1 — Identity: name + preferred-fuel (disabled when a vehicle
      // owns the fuel, #695) + the derived-fuel hint.
      SectionCard(
        title: l10n?.vehicleSectionIdentityTitle ?? 'Identity',
        leadingIcon: Icons.person_outline,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n?.profileName ?? 'Profile name',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: Spacing.xl),
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
              const SizedBox(height: Spacing.sm),
              Text(
                l10n?.profileFuelFromVehicleHint ??
                    'Fuel type is derived from your default vehicle. '
                        'Clear the vehicle to pick a fuel directly.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
      // 2 — Search radius.
      SectionCard(
        title: l10n?.defaultRadius ?? 'Default radius',
        leadingIcon: Icons.my_location,
        child: ProfileRadiusSlider(
          value: editState.radius,
          onChanged: editCtrl.setRadius,
        ),
      ),
      // 3 — Route planning (gated on Feature.routePlanning).
      if (routePlanningOn)
        SectionCard(
          title: l10n?.routePlanningSection ?? 'Route planning',
          leadingIcon: Icons.alt_route,
          child: _RouteSegmentSection(state: editState, ctrl: editCtrl),
        ),
      // 4 — Display & stations toggles.
      SectionCard(
        title:
            l10n?.profileSectionDisplayStations ?? 'Display & stations',
        leadingIcon: Icons.tune,
        child: _TogglesSection(state: editState, ctrl: editCtrl),
      ),
      // 5 — Station ratings.
      SectionCard(
        title: l10n?.privacyRatings ?? 'Station ratings',
        leadingIcon: Icons.reviews_outlined,
        child: _RatingModeSection(state: editState, ctrl: editCtrl),
      ),
      // 6 — Start screen.
      SectionCard(
        title: l10n?.landingScreen ?? 'Start screen',
        leadingIcon: Icons.home_outlined,
        child: ProfileLandingScreenDropdown(
          value: editState.landingScreen,
          onChanged: editCtrl.setLandingScreen,
        ),
      ),
      // 7 — Approach overlay.
      SectionCard(
        title: l10n?.approachOverlaySection ?? 'Approach-station overlay',
        leadingIcon: Icons.radar,
        child: _ApproachOverlaySection(state: editState, ctrl: editCtrl),
      ),
      // 8 — Vehicle (only when a vehicle exists).
      if (hasVehicles)
        SectionCard(
          title: l10n?.fillUpVehicleLabel ?? 'Vehicle',
          leadingIcon: Icons.directions_car_outlined,
          child: _DefaultVehicleSection(state: editState, ctrl: editCtrl),
        ),
      // 9 — Region: country + language under one card.
      SectionCard(
        title: l10n?.profileSectionRegion ?? 'Region',
        leadingIcon: Icons.public,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.profileCountry ?? 'Country',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: Spacing.md),
            _CountrySection(
              state: editState,
              ctrl: editCtrl,
              profileId: widget.profile.id,
            ),
            const SizedBox(height: Spacing.xl),
            Text(
              l10n?.profileLanguage ?? 'Language',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: Spacing.md),
            _LanguageSection(state: editState, ctrl: editCtrl),
          ],
        ),
      ),
      // 10 — Home postal code.
      SectionCard(
        title: l10n?.home ?? 'Home',
        leadingIcon: Icons.location_on_outlined,
        child: TextField(
          controller: _zipController,
          keyboardType: TextInputType.number,
          maxLength: editState.countryCode != null
              ? (Countries.byCode(editState.countryCode!)?.postalCodeLength ??
                  5)
              : 5,
          decoration: InputDecoration(
            labelText: l10n?.homeZip ?? 'Home postal code',
            border: const OutlineInputBorder(),
            counterText: '',
          ),
        ),
      ),
    ];

    final footer = _SaveDeleteActions(
      state: editState,
      profile: widget.profile,
      nameController: _nameController,
      zipController: _zipController,
      onSave: widget.onSave,
      onDelete: widget.onDelete,
      onConfirmDelete: () => _confirmDelete(context),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // Cap content width on tablets / landscape so the cards stay
            // a comfortable reading measure instead of stretching edge
            // to edge (#2551). Below 600 keep the plain single column.
            final wide = constraints.maxWidth >= 600;
            Widget constrain(Widget child) => wide
                ? Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: child,
                    ),
                  )
                : child;

            // The scrollController MUST stay wired to the inner ListView
            // or DraggableScrollableSheet drag-to-resize breaks (#2551).
            final list = ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(Spacing.xl),
              children: [
                // Cosmetic grabber.
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: Spacing.lg),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: AppRadius.sm,
                    ),
                  ),
                ),
                Text(
                  l10n?.editProfile ?? 'Edit profile',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: Spacing.xl),
                for (final card in cards) ...[
                  card,
                  const SizedBox(height: Spacing.md),
                ],
              ],
            );

            return Column(
              children: [
                Expanded(child: constrain(list)),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                constrain(
                  Padding(
                    padding: const EdgeInsets.all(Spacing.xl),
                    child: footer,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
