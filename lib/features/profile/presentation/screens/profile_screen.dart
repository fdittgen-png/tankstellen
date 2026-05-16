import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/settings_menu_tile.dart';
import '../../../consent/presentation/widgets/consent_settings_section.dart';
import '../../../driving/presentation/widgets/driving_settings_section.dart';
import '../../../feature_management/application/feature_flags_provider.dart';
import '../../../feature_management/domain/consumption_tab_visibility.dart';
import '../../../feature_management/domain/feature.dart';
import '../../../feature_management/domain/feature_dependency_graph.dart';
import '../../../sync/presentation/widgets/ntfy_setup.dart';
import '../../../widget/presentation/widget_help_section.dart';
import '../widgets/about_section.dart';
import '../widgets/api_key_section.dart';
import '../widgets/feature_management_section.dart';
import '../widgets/feedback_token_section.dart';
import '../widgets/location_section_widget.dart';
import '../widgets/profile_list_section.dart';
import '../widgets/storage_section.dart';
import '../widgets/tank_sync_section.dart';
import '../widgets/use_mode_section.dart';

/// Settings / profile screen that composes extracted section widgets.
///
/// Each major section is either always visible (Profile, Location, About)
/// or wrapped in a [_FoldableSection] for progressive disclosure.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    // Cascading-feature gates (#1447 phase 3). Sections whose root
    // feature is effectively-disabled vanish entirely so the user does
    // not see settings whose UI cannot do anything. Re-enabling the
    // root from the Feature management section restores them.
    final manifest = ref.watch(featureManifestProvider);
    final enabledFlags = ref.watch(enabledFeaturesProvider);
    final tankSyncOn = isEffectivelyEnabled(
      Feature.tankSync,
      manifest,
      enabledFlags,
    );
    // #1517 / #1520 — Consumption section is reachable when
    // `showConsumptionTab` is on AND at least one data source is on
    // (manualConsumption for Medium tier OR obd2TripRecording for Full
    // tier). Replaces the prior obd2-only gate so Medium-profile users
    // (manual fill-ups, no OBD2) can still configure their vehicle
    // and reach the Consumption surface.
    final consumptionOn = isConsumptionTabReachable(manifest, enabledFlags);

    return PageScaffold(
      title: l?.settings ?? 'Settings',
      // #530 — compact vertical spacing. Was `EdgeInsets.all(16)` plus
      // `SizedBox(height: 32)` between every major section, which ate
      // ~180 dp of whitespace on a single screen. Tightened to 8 dp
      // top / 16 dp sides + 16 dp section gaps + 4 dp header-to-body.
      bodyPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          // Use mode (#1517 / #1519) used to sit at the top of the
          // Settings screen; it now lives INSIDE the Consumption
          // _FoldableSection below so the use-mode chooser is grouped
          // with the consumption-tier-dependent toggles it gates.

          // Profiles — primary user-data section.
          SectionHeader(
            leadingIcon: Icons.person,
            title: l?.sectionProfile ?? 'Profile',
            padding: EdgeInsets.zero,
          ),
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
          // #1447 phase 3 — hidden entirely when Feature.tankSync is
          // effectively disabled. Stored TankSync config (account,
          // mode, etc.) is preserved; re-enabling the feature surfaces
          // the section with the prior configuration intact.
          if (tankSyncOn) ...[
            _FoldableSection(
              icon: Icons.cloud_outlined,
              title: 'TankSync', // i18n-ignore: brand name
              // #1696 — a localized descriptive subtitle so the
              // brand-named section isn't an unexplained label.
              subtitle: l?.tankSyncSectionSubtitle ??
                  'Cloud sync across your devices',
              // #1703 — the ntfy.sh push-setup card sits directly below
              // the sync status/actions; it self-handles the not-yet-
              // connected state with a "Connect TankSync first" hint.
              child: const Column(
                children: [
                  TankSyncSection(),
                  SizedBox(height: 8),
                  NtfySetupCard(),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // #952 phase 3 — bad-scan reporter PAT entry. Closed by
          // default; users without a token continue to use the
          // SharePlus fallback.
          _FoldableSection(
            icon: Icons.bug_report_outlined,
            title: l?.feedbackTokenSectionTitle ?? 'Bad-scan feedback (GitHub)',
            child: const FeedbackTokenSection(),
          ),
          const SizedBox(height: 8),

          // API Key — closed by default (unchanged).
          _FoldableSection(
            icon: Icons.key,
            title: l?.apiKeySetup ?? 'API Key',
            child: const ApiKeySection(),
          ),
          const SizedBox(height: 8),

          // #896 — Consumption log menu tile removed. The consumption
          // screen is already a top-level destination on the bottom
          // navigation bar, so a duplicate menu entry here was
          // redundant. Route `/consumption` remains registered in
          // `lib/app/router.dart` for direct navigation (station
          // detail CTA, deep links).

          // Theme — light / dark / follow system (#752, #897).
          // #897 — restyled as a `SettingsMenuTile` that navigates to
          // the dedicated `/theme-settings` screen so the Theme entry
          // matches the Privacy Dashboard and Storage card pattern
          // instead of opening a modal bottom sheet inline.
          SettingsMenuTile(
            icon: Icons.palette_outlined,
            title: l?.themeCardTitle ?? 'Theme',
            subtitle: _themeSubtitle(ref, l),
            onTap: () => context.push('/theme-settings'),
          ),
          const SizedBox(height: 8),

          // #1572 — Conso foldable contains every parameter that
          // pairs with a Conso functionality: Mes véhicules, optional
          // Trips (OBD2) sub-section, and the Driving toggles
          // (eco-coach, gamification, fuel-club). DrivingSettingsSection
          // itself owns the sub-section layout. The top-level
          // *Mes véhicules* tile added in #1568 was reverted here in
          // favour of the in-foldable sub-section header.
          if (consumptionOn) ...[
            _FoldableSection(
              icon: Icons.local_gas_station_outlined,
              title: l?.navConsumption ?? 'Consumption',
              child: const DrivingSettingsSection(),
            ),
            const SizedBox(height: 8),
          ],

          // #1806 — home-screen widget help. The Android widget's
          // per-widget config is OS-mediated (long-press → Reconfigure)
          // and can't be launched from the app, so this section is the
          // in-app discoverable surface for it.
          _FoldableSection(
            icon: Icons.widgets_outlined,
            title: l?.widgetHelpSectionTitle ?? 'Home-screen widget',
            child: const WidgetHelpSection(),
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
          const SizedBox(height: 8),

          // #1373 phase 2 — central feature-management toggles. Placed
          // near the bottom (above About, below Privacy) because most
          // users will never visit it; advanced controls don't belong
          // at the top of a settings screen.
          //
          // The Use-mode chooser (Basic / Medium / Full / Custom) sits
          // at the TOP of this section because picking a preset
          // overwrites every toggle below it — users discover the
          // chooser at the same time as the toggles it gates.
          _FoldableSection(
            icon: Icons.tune,
            title: l?.featureManagementSectionTitle ?? 'Feature management',
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                UseModeSection(),
                SizedBox(height: 12),
                FeatureManagementSection(),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // #534 — About moved to the very end, below Privacy.
          SectionHeader(
            leadingIcon: Icons.info_outline,
            title: l?.about ?? 'About',
            padding: EdgeInsets.zero,
          ),
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

  /// Optional one-line description shown under [title] (#1696) — e.g.
  /// explaining a brand-named section like "TankSync".
  final String? subtitle;
  final Widget child;

  const _FoldableSection({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleText = subtitle;
    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        leading: Icon(icon, size: 20),
        title: Text(title,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: subtitleText == null
            ? null
            : Text(
                subtitleText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
        initiallyExpanded: false,
        shape: const Border(),
        collapsedShape: const Border(),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: [child],
      ),
    );
  }
}

/// Active-mode subtitle on the Theme `SettingsMenuTile` (#897).
String _themeSubtitle(WidgetRef ref, AppLocalizations? l) {
  final choice = ref.watch(themeModeSettingProvider);
  switch (choice) {
    case AppThemeChoice.light:
      return l?.themeCardSubtitleLight ?? 'Light';
    case AppThemeChoice.dark:
      return l?.themeCardSubtitleDark ?? 'Dark';
    case AppThemeChoice.eco:
      return l?.themeSettingsEcoLabel ?? 'Eco';
    case AppThemeChoice.system:
      return l?.themeCardSubtitleSystem ?? 'System';
  }
}

