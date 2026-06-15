// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/country/location_coverage_provider.dart';
import '../../../../l10n/app_localizations.dart';

part 'unsupported_region_notice.g.dart';

/// #3361 — session dismissal of the location-coverage notice. Resets each app
/// launch (a light touch — the gap is worth re-surfacing once per session, not
/// nagging every rebuild). Kept out of storage on purpose.
@riverpod
class UnsupportedRegionDismissed extends _$UnsupportedRegionDismissed {
  @override
  bool build() => false;

  void dismiss() => state = true;
}

/// #3361 — a dismissible banner on the search screen that distinguishes the two
/// reasons a user might see no useful prices:
///
///  * [LocationCoverageStatus.unsupported] — their country has no provider:
///    the honest "not available in your region" message (replaces silently
///    showing German stations, which a Play reviewer read as a geo-restriction).
///  * [LocationCoverageStatus.needsProfile] — their country IS supported but
///    they never configured it, so the app fell back to the wrong country:
///    prompt them to set their country.
///
/// Purely informational + dismissible — it never blocks the app.
class UnsupportedRegionNotice extends ConsumerWidget {
  const UnsupportedRegionNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(locationCoverageProvider);
    final dismissed = ref.watch(unsupportedRegionDismissedProvider);
    final showable = status == LocationCoverageStatus.unsupported ||
        status == LocationCoverageStatus.needsProfile;
    if (!showable || dismissed) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final unsupported = status == LocationCoverageStatus.unsupported;
    return MaterialBanner(
      key: const Key('unsupported_region_notice'),
      forceActionsBelow: true,
      leading: Icon(
        unsupported ? Icons.public_off : Icons.flag_outlined,
        color: theme.colorScheme.primary,
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            unsupported
                ? l10n.unsupportedRegionTitle
                : l10n.configureCountryTitle,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            unsupported
                ? l10n.unsupportedRegionBody
                : l10n.configureCountryBody,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('unsupported_region_dismiss'),
          onPressed: () => ref
              .read(unsupportedRegionDismissedProvider.notifier)
              .dismiss(),
          child: Text(l10n.unsupportedRegionDismiss),
        ),
      ],
    );
  }
}
