import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../consent/presentation/widgets/consent_settings_section.dart';
import '../widgets/about_section.dart';
import '../widgets/api_key_section.dart';
import '../widgets/config_verification_widget.dart';
import '../widgets/data_transparency_section.dart';
import '../widgets/location_section_widget.dart';
import '../widgets/profile_list_section.dart';
import '../widgets/storage_section.dart';
import '../widgets/tank_sync_section.dart';

/// Settings / profile screen that composes extracted section widgets.
///
/// Each major section is either always visible (Profile, Location, About)
/// or wrapped in a [_FoldableSection] for progressive disclosure.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l?.settings ?? 'Settings'),
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Profiles
          const _SectionHeader(icon: Icons.person, title: 'Profile'),
          const SizedBox(height: 8),
          const ProfileListSection(),
          const SizedBox(height: 32),

          // Location
          const _SectionHeader(icon: Icons.my_location, title: 'Location'),
          const SizedBox(height: 8),
          const LocationSectionWidget(),
          const SizedBox(height: 32),

          // TankSync
          _FoldableSection(
            icon: Icons.cloud_outlined,
            title: 'TankSync',
            initiallyExpanded: true,
            child: const TankSyncSection(),
          ),
          const SizedBox(height: 8),

          // API Key
          _FoldableSection(
            icon: Icons.key,
            title: l?.apiKeySetup ?? 'API Key',
            child: const ApiKeySection(),
          ),
          const SizedBox(height: 8),

          // Data Transparency
          _FoldableSection(
            icon: Icons.visibility,
            title: l?.dataTransparency ?? 'Data transparency',
            child: const DataTransparencySection(),
          ),
          const SizedBox(height: 8),

          // Storage & Cache
          _FoldableSection(
            icon: Icons.storage,
            title: l?.storageAndCache ?? 'Storage & cache',
            child: const StorageSection(),
          ),
          const SizedBox(height: 32),

          // About
          _SectionHeader(
              icon: Icons.info_outline, title: l?.about ?? 'About'),
          const SizedBox(height: 8),
          const AboutSection(),
          const SizedBox(height: 32),

          // Privacy & Consent
          _FoldableSection(
            icon: Icons.privacy_tip_outlined,
            title: l?.gdprTitle ?? 'Privacy',
            child: const ConsentSettingsSection(),
          ),
          const SizedBox(height: 8),

          // Configuration Verification
          const _SectionHeader(
            icon: Icons.verified_user,
            title: 'Configuration & Privacy',
          ),
          const SizedBox(height: 8),
          const ConfigVerificationWidget(),
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 16),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared layout helpers (kept private to this file)
// ---------------------------------------------------------------------------

/// A foldable/unfoldable settings section with icon, title, and expandable content.
class _FoldableSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  const _FoldableSection({
    required this.icon,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        leading: Icon(icon, size: 20),
        title: Text(title,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        initiallyExpanded: initiallyExpanded,
        shape: const Border(),
        collapsedShape: const Border(),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: [child],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
