// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/country/country_config.dart';
import '../../../../core/language/language_provider.dart';
import '../../../../core/country/country_provider.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/user_profile.dart';
import '../../providers/profile_provider.dart';
import 'profile_edit_sheet.dart';

class ProfileListSection extends ConsumerWidget {
  const ProfileListSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProfile = ref.watch(activeProfileProvider);
    final profiles = ref.watch(allProfilesProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...profiles.map((profile) {
          final isActive = profile.id == activeProfile?.id;
          final cs = theme.colorScheme;
          return Card(
            color: isActive ? cs.primaryContainer : null,
            child: ListTile(
              // #2526 — the active card fills with `primaryContainer`, which in
              // dark is a pale green (`#C9E1CA`). Letting the title/subtitle and
              // leading icon default to `onSurface`/`onSurfaceVariant`
              // (near-white) collapsed the card to ~1.1:1. Pin the on-colour to
              // `onPrimaryContainer` (11:1) while active; inactive keeps the
              // theme default.
              textColor: isActive ? cs.onPrimaryContainer : null,
              iconColor: isActive ? cs.onPrimaryContainer : null,
              leading: Icon(
                isActive ? Icons.person : Icons.person_outline,
              ),
              title: Text(profile.name),
              subtitle: Text(
                '${profile.countryCode != null ? (Countries.byCode(profile.countryCode!)?.flag ?? "") : ""} '
                '${profile.preferredFuelType.displayName} | '
                '${profile.defaultSearchRadius.round()} km | '
                '${profile.landingScreen.localizedName(Localizations.localeOf(context).languageCode)}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isActive)
                    TextButton(
                      onPressed: () => _activateProfile(context, ref, profile),
                      child: Text(AppLocalizations.of(context)?.activate ?? 'Activate'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: AppLocalizations.of(context)?.editProfile ??
                        'Edit profile',
                    onPressed: () => _editProfile(context, ref, profile),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _createProfile(context, ref),
          icon: const Icon(Icons.add),
          label: Text(
              AppLocalizations.of(context)?.newProfile ?? 'New profile'),
        ),
      ],
    );
  }

  /// #2596 — activating a profile must immediately re-highlight the active
  /// card and flip every "Activate" button. `switchProfile` mutates the
  /// `ActiveProfile` notifier, but `allProfilesProvider` only recomputes
  /// once that mutation has completed, so we await it, then refresh the
  /// active provider and invalidate the list before surfacing feedback.
  Future<void> _activateProfile(
      BuildContext context, WidgetRef ref, UserProfile profile) async {
    // #3159 — capture the notifier BEFORE the await: Riverpod 3 throws a
    // StateError when a WidgetRef is used after the element unmounted, and
    // the user can leave the screen while switchProfile persists.
    final profileNotifier = ref.read(activeProfileProvider.notifier);
    await profileNotifier.switchProfile(profile.id);
    profileNotifier.refresh();
    if (!context.mounted) return;
    ref.invalidate(allProfilesProvider);
    final l10n = AppLocalizations.of(context);
    SnackBarHelper.showSuccess(
      context,
      l10n?.profileSwitchedTo(profile.name) ??
          'Switched to ${profile.name}',
    );
  }

  Future<void> _createProfile(BuildContext context, WidgetRef ref) async {
    // #3159 — every ref.read happens BEFORE the dialog await so a dismissal
    // that races the screen's disposal can't touch a dead WidgetRef.
    final country = ref.read(activeCountryProvider);
    final language = ref.read(activeLanguageProvider);
    final repo = ref.read(profileRepositoryProvider);
    final profileNotifier = ref.read(activeProfileProvider.notifier);

    final name = await _showNameDialog(
      context,
      AppLocalizations.of(context)?.newProfile ?? 'New profile',
      '',
    );
    if (name == null || name.isEmpty) return;

    // #2597 — one profile per country. A new profile defaults to the active
    // country, but if another profile already owns it we create the profile
    // WITHOUT a country (rather than blocking the whole flow); the user then
    // assigns a still-free country in the editor. This preserves the
    // invariant the border-cross auto-switch relies on.
    final countryTaken = repo.isCountryTaken(country.code);
    await repo.createProfile(
      name: name,
      countryCode: countryTaken ? null : country.code,
      languageCode: language.code,
    );
    // #2596 — `refresh()` alone only re-reads the *active* profile, which
    // does not change when a non-first profile is added, so the new card
    // never appeared. Invalidate the list provider so the new profile
    // shows immediately, then confirm with a SnackBar.
    profileNotifier.refresh();
    if (!context.mounted) return;
    ref.invalidate(allProfilesProvider);
    final l10n = AppLocalizations.of(context);
    SnackBarHelper.showSuccess(
      context,
      l10n?.profileCreatedNamed(name) ?? 'Profile $name created',
    );
  }

  Future<void> _editProfile(
      BuildContext context, WidgetRef ref, UserProfile profile) async {
    // Check how many profiles exist — the last one cannot be deleted
    final allProfiles = ref.read(allProfilesProvider);
    final canDelete = allProfiles.length > 1;
    // #3159 — the sheet's callbacks fire after awaits; capture the notifier
    // and repo now so neither callback touches the WidgetRef once this
    // section could have unmounted underneath the modal sheet.
    final profileNotifier = ref.read(activeProfileProvider.notifier);
    final repo = ref.read(profileRepositoryProvider);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // `_` (not `context`) so the mounted guards below check the section's
      // own element — the one `ref` belongs to — not the sheet's.
      builder: (_) => ProfileEditSheet(
        profile: profile,
        onSave: (updated) async {
          await profileNotifier.updateProfile(updated);
          // #2596 — refresh the active provider too so an edit to the
          // active profile's own fields (name, country) re-renders the
          // highlighted card, not just the list.
          profileNotifier.refresh();
          if (context.mounted) ref.invalidate(allProfilesProvider);
        },
        // Default profile (last remaining) cannot be deleted
        onDelete: canDelete ? () async {
          await repo.deleteProfile(profile.id);
          profileNotifier.refresh();
          if (context.mounted) ref.invalidate(allProfilesProvider);
        } : null,
      ),
    );
  }

  Future<String?> _showNameDialog(
      BuildContext context, String title, String initial) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)?.nameLabel ?? 'Name',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(AppLocalizations.of(context)?.save ?? 'Save'),
          ),
        ],
      ),
    );
    // Defer disposal to after the current frame: the dialog's dismiss
    // transition still reads the controller while animating out, so a
    // synchronous dispose here tears it down mid-frame (a
    // "TextEditingController used after disposed" assertion under the test
    // framework's pump-driven teardown). The post-frame hop lets the route
    // finish closing before we release it.
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    return result;
  }
}
