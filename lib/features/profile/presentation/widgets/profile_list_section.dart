import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/country/country_config.dart';
import '../../../../core/language/language_provider.dart';
import '../../../../core/country/country_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/profile_repository.dart';
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
          return Card(
            color: isActive ? theme.colorScheme.primaryContainer : null,
            child: ListTile(
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
                      onPressed: () {
                        ref
                            .read(activeProfileProvider.notifier)
                            .switchProfile(profile.id);
                      },
                      child: const Text('Aktivieren'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit),
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

  Future<void> _createProfile(BuildContext context, WidgetRef ref) async {
    final name = await _showNameDialog(
      context,
      AppLocalizations.of(context)?.newProfile ?? 'New profile',
      '',
    );
    if (name == null || name.isEmpty) return;

    final country = ref.read(activeCountryProvider);
    final language = ref.read(activeLanguageProvider);
    final repo = ref.read(profileRepositoryProvider);
    await repo.createProfile(
      name: name,
      countryCode: country.code,
      languageCode: language.code,
    );
    ref.read(activeProfileProvider.notifier).refresh();
  }

  Future<void> _editProfile(
      BuildContext context, WidgetRef ref, UserProfile profile) async {
    // Check how many profiles exist — the last one cannot be deleted
    final allProfiles = ref.read(allProfilesProvider);
    final canDelete = allProfiles.length > 1;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ProfileEditSheet(
        profile: profile,
        onSave: (updated) async {
          await ref
              .read(activeProfileProvider.notifier)
              .updateProfile(updated);
          ref.invalidate(allProfilesProvider);
        },
        // Default profile (last remaining) cannot be deleted
        onDelete: canDelete ? () async {
          final repo = ref.read(profileRepositoryProvider);
          await repo.deleteProfile(profile.id);
          ref.read(activeProfileProvider.notifier).refresh();
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
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(AppLocalizations.of(context)?.save ?? 'Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }
}
