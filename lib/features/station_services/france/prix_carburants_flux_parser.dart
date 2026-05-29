// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Pure parsing helpers for the French *flux instantané* bulk source (#2277).
///
/// The whole-country flux is published as a ZIP holding a single XML file
/// (`PrixCarburants_instantane.xml`), refreshed every ~10 minutes. This module
/// turns the raw ZIP bytes — or the inner XML string — into [Station]s without
/// touching Dio, persistence, or any network state, so the ZIP/XML-shape
/// contract (the thing the upstream breaks first) is exercised with small
/// committed fixtures. Adding network or storage imports here defeats the
/// point of the split, exactly as in `prix_carburants_parsers.dart`.
///
/// Schema (per the gouv.fr open-data documentation):
///  - `<pdv id="…" latitude="…" longitude="…" cp="…" pop="…">` — coordinates
///    are GeoDecimal × 100000 (divide by 100000 for WGS84).
///  - `<adresse>` / `<ville>` child elements.
///  - `<prix nom="Gazole|SP95|SP98|E10|E85|GPLc" valeur="…" maj="…"/>` — value
///    in euros. A defensive thousandths fallback (value > 100 → ÷1000) guards
///    the v1-style integer encoding without affecting euro-valued feeds.
///
/// Fuel-name → [Station] field mapping mirrors the legacy JSON parser exactly
/// (`SP95→e5`, `E10→e10`, `SP98→e98`, `Gazole→diesel`, `E85→e85`, `GPLc→lpg`)
/// and ids carry the `fr-` country prefix, so a given area returns the same
/// stations the polled path returned.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import '../../search/domain/entities/station.dart';

/// Decode the flux ZIP [bytes], locate the inner XML entry, and parse every
/// point-of-sale into a [Station] (distance 0 — the caller stamps it per
/// search). Returns `[]` when the ZIP holds no XML entry or it is empty.
List<Station> parseFluxZip(List<int> bytes) {
  final xml = extractFluxXml(bytes);
  if (xml == null || xml.isEmpty) return const [];
  return parseFluxXml(xml);
}

/// Pull the inner XML document text out of the flux ZIP. The archive holds a
/// single `*.xml` entry; we take the first XML file regardless of its exact
/// name so a rename upstream doesn't break parsing. Tolerant of Latin-1 /
/// UTF-8 payloads (the flux is ISO-8859-1 historically).
String? extractFluxXml(List<int> bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  for (final file in archive.files) {
    if (!file.isFile) continue;
    if (!file.name.toLowerCase().endsWith('.xml')) continue;
    return _decodeBytes(file.content);
  }
  return null;
}

/// Decode raw file bytes to a String, preferring UTF-8 and falling back to
/// Latin-1 (the flux XML is historically ISO-8859-1, which UTF-8 rejects on
/// accented bytes like the `é` in "Carrefour Hérault").
String _decodeBytes(Uint8List bytes) {
  try {
    return utf8.decode(bytes);
  } on FormatException {
    return latin1.decode(bytes, allowInvalid: true);
  }
}

/// Parse the flux XML document text into [Station]s. Exposed separately so the
/// XML-shape contract can be tested without zipping a fixture first.
List<Station> parseFluxXml(String xml) {
  final XmlDocument doc;
  try {
    doc = XmlDocument.parse(xml);
  } on XmlException {
    return const [];
  }

  final stations = <Station>[];
  for (final pdv in doc.findAllElements('pdv')) {
    final station = parseFluxPdv(pdv);
    if (station != null) stations.add(station);
  }
  return stations;
}

/// Parse a single `<pdv>` element into a [Station], or `null` when it carries
/// no usable coordinates. Public for direct unit testing.
Station? parseFluxPdv(XmlElement pdv) {
  final lat = _coord(pdv.getAttribute('latitude'));
  final lng = _coord(pdv.getAttribute('longitude'));
  if (lat == null || lng == null || lat == 0 || lng == 0) return null;

  final rawId = pdv.getAttribute('id')?.trim() ?? '';
  final cp = pdv.getAttribute('cp')?.trim() ?? '';
  final pop = pdv.getAttribute('pop')?.trim() ?? '';
  final adresse = pdv.findElements('adresse').firstOrNull?.innerText.trim() ?? '';
  final ville = pdv.findElements('ville').firstOrNull?.innerText.trim() ?? '';

  double? e5, e10, e98, diesel, e85, lpg;
  String? mostRecentMaj;
  for (final prix in pdv.findElements('prix')) {
    final nom = (prix.getAttribute('nom') ?? '').trim().toUpperCase();
    final value = _price(prix.getAttribute('valeur'));
    if (value == null) continue;
    switch (nom) {
      case 'SP95':
        e5 ??= value;
        break;
      case 'E10':
        e10 ??= value;
        break;
      case 'SP98':
        e98 ??= value;
        break;
      case 'GAZOLE':
        diesel ??= value;
        break;
      case 'E85':
        e85 ??= value;
        break;
      case 'GPLC':
        lpg ??= value;
        break;
    }
    final maj = prix.getAttribute('maj');
    if (maj != null && maj.isNotEmpty) {
      if (mostRecentMaj == null || maj.compareTo(mostRecentMaj) > 0) {
        mostRecentMaj = maj;
      }
    }
  }

  // #753 — scope the id with the `fr-` country prefix (matches the legacy
  // JSON parser) so a French numeric id cannot collide with another country.
  return Station(
    id: rawId.isEmpty ? '' : (rawId.startsWith('fr-') ? rawId : 'fr-$rawId'),
    name: adresse,
    brand: _brandFor(pop, adresse, ville),
    street: adresse,
    postCode: cp,
    place: ville,
    lat: lat,
    lng: lng,
    dist: 0,
    e5: e5,
    e10: e10,
    e98: e98,
    diesel: diesel,
    e85: e85,
    lpg: lpg,
    isOpen: true,
    updatedAt: _formatMaj(mostRecentMaj),
    stationType: pop.isEmpty ? null : pop,
  );
}

/// GeoDecimal coordinate → WGS84 degrees (÷ 100000). Tolerates a value that is
/// already in degrees (|v| ≤ 180) so a future schema that drops the scaling
/// still parses.
double? _coord(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final v = double.tryParse(raw.trim());
  if (v == null) return null;
  return v.abs() > 180 ? v / 100000 : v;
}

/// Coerce the `valeur` attribute to euros. Documented as euros (e.g. 1.659);
/// the `> 100` guard converts the legacy v1-style thousandths encoding
/// (e.g. 1659) without disturbing euro-valued feeds.
double? _price(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final v = double.tryParse(raw.trim().replaceAll(',', '.'));
  if (v == null) return null;
  return v > 100 ? v / 1000 : v;
}

/// Format the most-recent `maj` ISO timestamp as `dd/MM HH:mm`, mirroring the
/// legacy parser's `parsePrixCarburantsMostRecentUpdate` output shape.
String? _formatMaj(String? maj) {
  if (maj == null || maj.isEmpty) return null;
  try {
    final dt = DateTime.parse(maj);
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  } on FormatException {
    final cut = maj.length >= 16 ? maj.substring(0, 16) : maj;
    return cut.replaceAll('T', ' ');
  }
}

/// The flux XML carries no brand column, so reuse the autoroute fallback the
/// legacy path uses: `pop == 'A'` → highway service area, else the `Independent`
/// sentinel (#482) rendered as a localised "independent station" row. Address /
/// ville substring brand detection stays in the legacy enricher path.
String _brandFor(String pop, String adresse, String ville) {
  if (pop == 'A') return 'Autoroute';
  return 'Independent';
}
