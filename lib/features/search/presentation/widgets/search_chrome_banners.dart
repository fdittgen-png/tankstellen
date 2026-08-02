// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/country/country_config.dart';
import '../../../../core/location/user_position_provider.dart';
import '../../../../core/error/guarded.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/search_provider.dart';
import '../../../../core/location/location_consent.dart';
import 'demo_mode_banner.dart';
import 'search_summary_bar.dart';
import 'unsupported_region_notice.dart';
import 'user_position_bar.dart';

/// The search screen's chrome column — demo banner, unsupported-region
/// notice, summary bar, user-position bar. Extracted from
/// `search_screen.dart` under the 400-line norm (#3615), which also
/// wrapped the whole group in [AnimatedSize] so banners appear and
/// disappear as a motion instead of a post-frame layout jump.
class SearchChromeBanners extends ConsumerWidget {
  const SearchChromeBanners({
    super.key,
    required this.hidden,
    required this.country,
    required this.corridorCountryCodes,
    required this.onSearchAgain,
  });

  /// #3372 — landscape radar owns the pane: collapse the chrome.
  final bool hidden;
  final CountryConfig country;
  final Set<String> corridorCountryCodes;

  /// Re-runs the GPS search after a successful position update while
  /// results are showing.
  final Future<void> Function() onSearchAgain;

  Future<void> _updatePosition(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(settingsStorageProvider);
    // #3159 — capture before the consent/GPS awaits; ref.read on an
    // unmounted element throws a StateError under Riverpod 3.
    final positionNotifier = ref.read(userPositionProvider.notifier);
    if (!LocationConsentDialog.hasConsent(settings)) {
      if (!context.mounted) return;
      final consented = await LocationConsentDialog.show(context);
      if (!consented) return;
      await LocationConsentDialog.recordConsent(settings);
    }
    try {
      await positionNotifier.updateFromGps();
      if (!context.mounted) return;
      final state = ref.read(searchStateProvider);
      if (state.hasValue && state.value!.data.isNotEmpty) {
        unawaited(onSearchAgain());
      }
    } catch (e, st) {
      // #1692 — never surface a raw exception toString() to the user;
      // show a localized, actionable message instead. #2146 — route to
      // the exportable log so the cause is recoverable from a report.
      logFailure(e, st, where: 'SearchScreen: userPosition.updateFromGps');
      if (!context.mounted) return;
      SnackBarHelper.showError(
        context,
        AppLocalizations.of(context).searchFailedSnackbar,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: hidden
          ? const SizedBox(width: double.infinity)
          : Column(
              children: [
                DemoModeBanner(
                  country: country,
                  corridorCountryCodes: corridorCountryCodes,
                ),
                // #3361 — honest "no coverage for your country" notice
                // (replaces the silent fall-back to Germany that read
                // as a geo-restriction).
                const UnsupportedRegionNotice(),
                // Compact summary bar — entry point for editing criteria.
                const SearchSummaryBar(),
                UserPositionBar(
                  onUpdatePosition: () => _updatePosition(context, ref),
                ),
              ],
            ),
    );
  }
}
