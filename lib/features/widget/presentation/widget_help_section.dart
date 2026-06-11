// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../profile/domain/entities/user_profile.dart';
import '../../profile/providers/profile_provider.dart';
import '../data/widget_color_schemes.dart';
import '../data/widget_variants.dart';

/// In-app help + defaults editor for the home-screen widget
/// (#1806 / #2106).
///
/// The Android widget's per-widget Reconfigure flow is OS-mediated
/// (long-press → Reconfigure) and cannot be launched from inside the
/// app. #2106 surfaced the two most-asked defaults — colour scheme
/// and content variant — directly in this section so the user can
/// change them without ever opening the Reconfigure activity. Values
/// persist on the active [UserProfile] and propagate to the Android
/// renderer via `home_widget_service._writeGlobalWidgetDefaults` on
/// every refresh.
class WidgetHelpSection extends ConsumerWidget {
  const WidgetHelpSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // Defensive read: in widget tests without the profile graph
    // wired (or pre-onboarding cold start) the provider throws.
    // Fall back to the legacy Reconfigure hint in those cases so
    // the Settings screen never blanks on the help section.
    UserProfile? profile;
    try {
      profile = ref.watch(activeProfileProvider);
    } catch (_) {
      profile = null;
    }

    final lines = <String>[
      l?.widgetHelpIntro ??
          'Add the SparKilo widget to your home screen to see fuel and '
              'charging prices at a glance.',
      l?.widgetHelpAdd ??
          "Add it from your launcher's widget picker — long-press an "
              'empty area of the home screen, choose Widgets, and find '
              'SparKilo.',
      l?.widgetHelpTap ??
          'Tap a station in the widget to open it in the app. Tap the '
              'refresh icon to update prices.',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines) ...[
            Text(line, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
          ],
          // #2106 — the defaults editor only renders when the user
          // has an active profile (the values persist on it). On a
          // fresh install before onboarding, fall back to the legacy
          // "long-press → Reconfigure" hint.
          if (profile != null)
            _WidgetDefaultsEditor(profile: profile)
          else
            Text(
              l?.widgetHelpConfigure ??
                  'On Android, long-press the widget and choose '
                      'Reconfigure to change the profile, colour, and '
                      'content.',
              style: theme.textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

class _WidgetDefaultsEditor extends ConsumerWidget {
  final UserProfile profile;

  const _WidgetDefaultsEditor({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
          l?.widgetDefaultsApplyToAllHint ??
              'Choices below apply to every installed widget on the '
                  'next refresh.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l?.widgetDefaultsColorLabel ?? 'Colour scheme',
          style: theme.textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          key: const Key('widget_color_scheme_dropdown'),
          initialValue: profile.widgetColorScheme,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(),
          ),
          items: [
            for (final scheme in widgetColorSchemes)
              DropdownMenuItem(
                value: scheme,
                child: Text(_localizedSchemeLabel(l, scheme)),
              ),
          ],
          onChanged: (next) {
            if (next == null) return;
            _save(ref, profile.copyWith(widgetColorScheme: next));
          },
        ),
        const SizedBox(height: 12),
        Text(
          l?.widgetDefaultsVariantLabel ?? 'Content variant',
          style: theme.textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        SegmentedButton<String>(
          key: const Key('widget_variant_segmented'),
          selected: {profile.widgetVariant},
          segments: [
            ButtonSegment(
              value: defaultWidgetVariant,
              label: Text(l?.widgetVariantDefault ?? 'Default'),
            ),
            ButtonSegment(
              value: predictiveWidgetVariant,
              label: Text(l?.widgetVariantPredictive ?? 'Predictive'),
            ),
          ],
          onSelectionChanged: (sel) {
            final next = sel.first;
            _save(ref, profile.copyWith(widgetVariant: next));
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _save(WidgetRef ref, UserProfile next) {
    // The notifier returns a Future but we don't need to await — the
    // Riverpod listeners watching activeProfileProvider repaint as
    // soon as Hive returns. Errors are surfaced via the provider's
    // own logging.
    unawaited(ref.read(activeProfileProvider.notifier).updateProfile(next));
  }

  static String _localizedSchemeLabel(
    AppLocalizations? l,
    String scheme,
  ) {
    switch (scheme) {
      case 'system':
        return l?.widgetColorSchemeSystem ?? 'Follow system';
      case 'light':
        return l?.widgetColorSchemeLight ?? 'Light';
      case 'dark':
        return l?.widgetColorSchemeDark ?? 'Dark';
      case 'blue':
        return l?.widgetColorSchemeBlue ?? 'Blue';
      case 'green':
        return l?.widgetColorSchemeGreen ?? 'Green';
      case 'orange':
        return l?.widgetColorSchemeOrange ?? 'Orange';
      default:
        return scheme;
    }
  }
}
