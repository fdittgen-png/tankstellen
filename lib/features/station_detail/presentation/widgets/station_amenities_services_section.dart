// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/domain/station.dart';
import '../../../../core/domain/station_amenity.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/presentation/widgets/amenity_chips.dart';

/// The ONE "Amenities & services" section of the station-detail screen
/// (#3928, epic #3925).
///
/// Before this, the screen carried two sibling blocks fed by two sources
/// that overlap almost completely: the typed [StationAmenity] chips
/// (parsed from the API's service strings by
/// [parseAmenitiesFromServices]) under "Amenities", and — a few rows
/// lower — an expandable "Services (N)" listing the SAME raw strings
/// again. A French forecourt therefore showed `Lavage · Air · DAB` and
/// then, one tap away, `Station de lavage`, `Gonflage`, `Distributeur`.
///
/// The merge rule
/// --------------
/// Both lists are folded into one, deduplicated on a normalised key:
/// lower-cased, accent-stripped, non-alphanumerics removed, then mapped
/// through [_synonyms] so `Station de lavage` and `Lavage` collapse onto
/// the same `carwash` bucket as [StationAmenity.carWash]. The typed
/// amenity wins the slot (it carries an icon and a translated label);
/// the raw string only survives when it says something the amenity set
/// does not.
///
/// The first [_maxVisible] entries render immediately; the rest hide
/// behind a "Show more (n)" text button, which replaces the old
/// collapsed-by-default `ExpansionTile` — a short list is no longer
/// hidden behind a tap just because a highway station's list is long.
class StationAmenitiesServicesSection extends StatefulWidget {
  final Station station;

  const StationAmenitiesServicesSection({super.key, required this.station});

  @override
  State<StationAmenitiesServicesSection> createState() =>
      _StationAmenitiesServicesSectionState();
}

/// Chips shown before the "Show more" fold kicks in.
const int _maxVisible = 8;

class _StationAmenitiesServicesSectionState
    extends State<StationAmenitiesServicesSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final amenities = widget.station.amenities.toList();
    final services = mergedServiceLabels(
      amenities: widget.station.amenities,
      services: widget.station.services,
    );

    final total = amenities.length + services.length;
    if (total == 0) return const SizedBox.shrink();

    final visibleAmenityCount = _expanded
        ? amenities.length
        : (amenities.length < _maxVisible ? amenities.length : _maxVisible);
    final serviceSlots = _expanded ? services.length : _maxVisible - visibleAmenityCount;
    final visibleServiceCount = serviceSlots < 0
        ? 0
        : (serviceSlots > services.length ? services.length : serviceSlots);
    final hidden = total - visibleAmenityCount - visibleServiceCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.amenitiesAndServices,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        if (visibleAmenityCount > 0)
          AmenityChips(
            amenities: amenities.take(visibleAmenityCount).toSet(),
            maxVisible: visibleAmenityCount,
          ),
        if (visibleAmenityCount > 0 && visibleServiceCount > 0)
          const SizedBox(height: 4),
        if (visibleServiceCount > 0)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final label in services.take(visibleServiceCount))
                Chip(
                  avatar: const Icon(Icons.check_circle_outline, size: 16),
                  label: Text(label, style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        if (hidden > 0 || _expanded)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              key: const ValueKey('station-detail-amenities-services-fold'),
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded
                    ? l10n.amenitiesServicesShowLess
                    : l10n.amenitiesServicesShowMore(hidden),
              ),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// The raw service strings that survive deduplication against
/// [amenities] and against each other, in source order.
///
/// Exposed as a top-level function (not a private method) so the merge
/// rule can be unit-tested without pumping a widget.
List<String> mergedServiceLabels({
  required Set<StationAmenity> amenities,
  required List<String> services,
}) {
  final seen = <String>{for (final a in amenities) _amenityKey(a)};
  final kept = <String>[];
  for (final raw in services) {
    final label = raw.trim();
    if (label.isEmpty) continue;
    final key = normaliseAmenityKey(label);
    if (key.isEmpty || !seen.add(key)) continue;
    kept.add(label);
  }
  return kept;
}

/// Normalised dedup key for a free-text service label: lower-cased,
/// accents stripped, everything that is not a letter or a digit removed,
/// then folded through the [_synonyms] table.
///
/// `"Station de lavage"` → `"stationdelavage"` → `"carwash"`, the same
/// bucket `"Lavage"` and [StationAmenity.carWash] land in.
String normaliseAmenityKey(String label) {
  final buffer = StringBuffer();
  for (final rune in label.toLowerCase().runes) {
    final ch = String.fromCharCode(rune);
    final folded = _accents[ch] ?? ch;
    for (final c in folded.codeUnits) {
      final isDigit = c >= 0x30 && c <= 0x39;
      final isLetter = c >= 0x61 && c <= 0x7a;
      if (isDigit || isLetter) buffer.writeCharCode(c);
    }
  }
  final plain = buffer.toString();
  return _synonyms[plain] ?? plain;
}

String _amenityKey(StationAmenity amenity) => switch (amenity) {
      StationAmenity.shop => 'shop',
      StationAmenity.carWash => 'carwash',
      StationAmenity.airPump => 'airpump',
      StationAmenity.toilet => 'toilet',
      StationAmenity.restaurant => 'restaurant',
      StationAmenity.atm => 'atm',
      StationAmenity.wifi => 'wifi',
      StationAmenity.ev => 'ev',
    };

/// Latin-1/Latin-2 letters the French, German, Spanish, Italian and
/// Czech service strings actually carry, folded to ASCII so
/// `"Café"`/`"Cafe"` and `"Lavage"`/`"Lávage"` share one key.
const Map<String, String> _accents = <String, String>{
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'ą': 'a',
  'ç': 'c', 'ć': 'c', 'č': 'c',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ę': 'e', 'ě': 'e',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
  'ñ': 'n', 'ń': 'n', 'ň': 'n',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o',
  'ř': 'r', 'ś': 's', 'š': 's', 'ß': 'ss',
  'ť': 't',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ů': 'u',
  'ý': 'y', 'ÿ': 'y', 'ź': 'z', 'ż': 'z', 'ž': 'z',
  'œ': 'oe', 'æ': 'ae',
};

/// Small synonym table: the wordings the upstream APIs actually emit for
/// something the typed [StationAmenity] set already covers. Keys are
/// already normalised (lower-case, accent-free, alphanumerics only).
///
/// Deliberately conservative — a service the app has no amenity for
/// (`"Piste poids lourds"`, `"Automate CB 24/24"`) keeps its own bucket
/// and is shown verbatim.
const Map<String, String> _synonyms = <String, String>{
  // Car wash — FR prix-carburants emits several spellings.
  'lavage': 'carwash',
  'lavageautomatique': 'carwash',
  'lavagemanuel': 'carwash',
  'stationdelavage': 'carwash',
  'waschanlage': 'carwash',
  'carwash': 'carwash',
  // Shop.
  'boutique': 'shop',
  'boutiquealimentaire': 'shop',
  'magasin': 'shop',
  'epicerie': 'shop',
  'shop': 'shop',
  // Cash machine.
  'dab': 'atm',
  'distributeur': 'atm',
  'distributeurautomatiquedebillets': 'atm',
  'geldautomat': 'atm',
  'atm': 'atm',
  // Air / tyre inflation.
  'air': 'airpump',
  'gonflage': 'airpump',
  'gonflagedespneus': 'airpump',
  'luftdruck': 'airpump',
  // Toilets.
  'toilettes': 'toilet',
  'toilettespubliques': 'toilet',
  'toilette': 'toilet',
  'wc': 'toilet',
  // Food.
  'restaurant': 'restaurant',
  'restauration': 'restaurant',
  'restaurationarapideemporter': 'restaurant',
  'resto': 'restaurant',
  // Connectivity.
  'wifi': 'wifi',
  'wlan': 'wifi',
  // Charging.
  'borneelectrique': 'ev',
  'rechargeelectrique': 'ev',
  'ladestation': 'ev',
};
