// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/domain/brand_logo_manifest.dart';
import '../../../../../core/error/guarded.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/widgets/section_card.dart';
import '../../../../../l10n/app_localizations.dart';
import 'settings_topic_scaffold.dart';

/// Settings → About → Logo credits (#3940).
///
/// Every logo bundled with the app comes from Wikimedia Commons under a
/// free licence (public domain, or CC-BY / CC-BY-SA / CC0). CC-BY and
/// CC-BY-SA both REQUIRE attribution, so this screen is not decoration:
/// it is the licence condition being met. Each row names the file's
/// licence template and author and links to the Commons file page, which
/// is where a reader can verify both.
///
/// The trademark notice at the bottom answers the separate question a
/// public-domain file does not: copyright and trademark are different
/// rights, and showing a brand's mark to identify that brand's station
/// is nominative use.
class LogoCreditsScreen extends StatelessWidget {
  const LogoCreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final logos = BrandLogoManifest.all;

    return SettingsTopicScaffold(
      title: l.logoCreditsTitle,
      children: [
        SettingsGroupHeader(
          icon: Icons.workspace_premium_outlined,
          title: l.logoCreditsTitle,
        ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.logoCreditsIntro, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text(
                l.logoCreditsMonogramNote,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SectionCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final logo in logos) _LogoCreditRow(logo: logo),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SectionCard(
          child: Text(
            l.logoCreditsTrademarkNotice,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// One bundled logo: its own artwork, the brand it depicts, and the
/// licence + author the file is used under.
class _LogoCreditRow extends StatelessWidget {
  const _LogoCreditRow({required this.logo});

  final BrandLogoAsset logo;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: AppRadius.md,
        ),
        // The credited artwork itself — no ARB string: it IS the logo.
        child: Image.asset(logo.assetPath, fit: BoxFit.contain),
      ),
      // Brand, licence template and author are DATA reproduced from
      // Wikimedia Commons, never translatable copy — they arrive from the
      // generated manifest, so no literal reaches the widget tree.
      title: Text(logo.brand),
      subtitle: Text(l.logoCreditsEntryDetails(logo.licence, logo.author)),
      trailing: IconButton(
        icon: const Icon(Icons.open_in_new, size: 18),
        tooltip: l.logoCreditsOpenFilePage,
        onPressed: () => _openSource(logo.sourceUrl),
      ),
    );
  }

  void _openSource(String url) {
    if (url.isEmpty) return;
    try {
      unawaited(
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)
            .catchError((Object e, StackTrace st) {
          logFailure(e, st, where: 'LogoCreditsScreen: launch source');
          return false;
        }),
      );
    } on Object catch (e, st) {
      logFailure(e, st, where: 'LogoCreditsScreen: parse source url');
    }
  }
}
