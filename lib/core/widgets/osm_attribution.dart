// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../l10n/app_localizations.dart';

/// The proper-noun brand credited in the OpenStreetMap tile attribution.
///
/// Kept as a single literal so it is never mistranslated and so the
/// `mapAttributionOsm` ARB key only ever carries the translatable
/// structural wording around it (#2402). OpenStreetMap's tile-usage
/// policy mandates this visible credit on every map.
const String _osmBrand = 'OpenStreetMap'; // i18n-ignore: brand / proper noun

/// Builds the localized OpenStreetMap tile-attribution string
/// ("© OpenStreetMap contributors") for the current locale, with the
/// brand kept literal.
///
/// Shared by every flutter_map screen so the wrapper text lives in ARB
/// in exactly one place (#2402). Falls back to an English composition if
/// localizations are not yet available.
String osmAttributionText(BuildContext context) {
  final l = AppLocalizations.of(context);
  return l?.mapAttributionOsm(_osmBrand) ?? '© $_osmBrand contributors';
}

/// The standard flutter_map [RichAttributionWidget] credit for the
/// OpenStreetMap tile source, with its label sourced from ARB (#2402).
///
/// Reused across the station, driving, trip-path, radius-picker and
/// trajets maps so the attribution wording is localized once.
class OsmAttribution extends StatelessWidget {
  const OsmAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    return RichAttributionWidget(
      attributions: [
        TextSourceAttribution(osmAttributionText(context)),
      ],
    );
  }
}
