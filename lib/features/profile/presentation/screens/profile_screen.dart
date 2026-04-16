import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../consent/presentation/widgets/consent_settings_section.dart';
import '../widgets/about_section.dart';
import '../widgets/api_key_section.dart';
import '../widgets/location_section_widget.dart';
import '../widgets/profile_list_section.dart';
import '../widgets/settings_menu_tile.dart';
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
        // #530 — compact vertical spacing. Was `EdgeInsets.all(16)` plus
        // `SizedBox(height: 32)` between every major section, which ate
        // ~180 dp of whitespace on a single screen. Tightened to 8 dp
        // top / 16 dp sides + 16 dp section gaps + 4 dp header-to-body.
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          // Profiles — always visible, the primary interaction on the
          // Settings screen.
          _SectionHeader(icon: Icons.person, title: l?.sectionProfile ?? 'Profile'),
          const SizedBox(height: 4),
          const ProfileListSection(),
          const SizedBox(height: 16),

          // #534 — Location wrapped in _FoldableSection, closed by
          // default. The user rarely changes location preferences
          // after the initial setup.
          _FoldableSection(
            icon: Icons.my_location,
            title: l?.sectionLocation ?? 'Location',
            child: const LocationSectionWidget(),
          ),
          const SizedBox(height: 8),

          // #534 — TankSync closed by default (was initiallyExpanded: true).
          const _FoldableSection(
            icon: Icons.cloud_outlined,
            title: 'TankSync',
            child: TankSyncSection(),
          ),
          const SizedBox(height: 8),

          // API Key — closed by default (unchanged).
          _FoldableSection(
            icon: Icons.key,
            title: l?.apiKeySetup ?? 'API Key',
            child: const ApiKeySection(),
          ),
          const SizedBox(height: 8),

          // My vehicles
          SettingsMenuTile(
            icon: Icons.directions_car,
            title: l?.vehiclesMenuTitle ?? 'My vehicles',
            subtitle: l?.vehiclesMenuSubtitle ??
                'Battery, connectors, charging preferences',
            onTap: () => context.push('/vehicles'),
          ),
          const SizedBox(height: 8),

          // Fuel consumption log
          SettingsMenuTile(
            icon: Icons.local_gas_station,
            title: l?.consumptionLogMenuTitle ?? 'Consumption log',
            subtitle: l?.consumptionLogMenuSubtitle ??
                'Track fill-ups and calculate L/100km',
            onTap: () => context.push('/consumption'),
          ),
          const SizedBox(height: 8),

          // Storage & Cache
          _FoldableSection(
            icon: Icons.storage,
            title: l?.storageAndCache ?? 'Storage & cache',
            child: const StorageSection(),
          ),
          const SizedBox(height: 8),

          // Privacy & Consent
          _FoldableSection(
            icon: Icons.privacy_tip_outlined,
            title: l?.gdprTitle ?? 'Privacy',
            child: const ConsentSettingsSection(),
          ),
          const SizedBox(height: 8),

          // Privacy Dashboard
          SettingsMenuTile(
            icon: Icons.privacy_tip,
            title: l?.privacyDashboardTitle ?? 'Privacy Dashboard',
            subtitle: l?.privacyDashboardSubtitle ??
                'View, export, or delete your data',
            onTap: () => context.push('/privacy-dashboard'),
          ),
          const SizedBox(height: 16),

          // #534 — About moved to the very end, below Privacy.
          _SectionHeader(
              icon: Icons.info_outline, title: l?.about ?? 'About'),
          const SizedBox(height: 4),
          const AboutSection(),
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
///
/// #534 — all sections start **collapsed** (`initiallyExpanded: false` on
/// the inner `ExpansionTile`). This keeps the Paramètres screen compact
/// on load and lets the user expand only the section they care about.
class _FoldableSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _FoldableSection({
    required this.icon,
    required this.title,
    required this.child,
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
        initiallyExpanded: false,
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
    return Semantics(
      header: true,
      child: Row(
        children: [
          ExcludeSemantics(child: Icon(icon, size: 20)),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
