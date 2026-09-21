// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// Persisted-dataset model + JSON codec for the Italian MIMIT (ex-MISE)
/// service — extracted from `mise_station_service.dart` to keep that file
/// under the 400-line cap (#1680).
library;

/// #2270 — the parsed MISE dataset: the station registry joined-by-id with the
/// current prices. Both maps come from a single (two-file) download, so they
/// are persisted and rehydrated together as one record.
typedef MiseDataset = (Map<String, MiseStationData>, Map<String, MisePriceData>);

/// #2270 — JSON codec for the persisted IT dataset. Single-letter keys keep
/// the Hive footprint of the ~25k-station registry + price table down.
Map<String, dynamic> serializeMiseDataset(MiseDataset value) => {
      's': {for (final e in value.$1.entries) e.key: e.value.toJson()},
      'p': {for (final e in value.$2.entries) e.key: e.value.toJson()},
    };

MiseDataset? deserializeMiseDataset(Map<String, dynamic> json) {
  final stationsJson = json['s'];
  final pricesJson = json['p'];
  if (stationsJson is! Map || pricesJson is! Map) return null;
  final stations = <String, MiseStationData>{
    for (final e in stationsJson.entries)
      e.key as String:
          MiseStationData.fromJson(Map<String, dynamic>.from(e.value as Map)),
  };
  final prices = <String, MisePriceData>{
    for (final e in pricesJson.entries)
      e.key as String:
          MisePriceData.fromJson(Map<String, dynamic>.from(e.value as Map)),
  };
  return (stations, prices);
}

class MiseStationData {
  final String brand;
  final String type;
  final String name;
  final String address;
  final String city;
  final String province;
  final double lat;
  final double lng;

  const MiseStationData({
    required this.brand,
    required this.type,
    required this.name,
    required this.address,
    required this.city,
    required this.province,
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toJson() => {
        'b': brand,
        't': type,
        'n': name,
        'a': address,
        'c': city,
        'pv': province,
        'la': lat,
        'lo': lng,
      };

  factory MiseStationData.fromJson(Map<String, dynamic> j) => MiseStationData(
        brand: j['b'] as String? ?? '',
        type: j['t'] as String? ?? '',
        name: j['n'] as String? ?? '',
        address: j['a'] as String? ?? '',
        city: j['c'] as String? ?? '',
        province: j['pv'] as String? ?? '',
        lat: (j['la'] as num?)?.toDouble() ?? 0,
        lng: (j['lo'] as num?)?.toDouble() ?? 0,
      );
}

/// A MIMIT `dtComu` stamp ("04/06/2026 07:44:20") as a real instant
/// (#4309). Null when [raw] is missing or is not a valid day-first
/// `dd/MM/yyyy HH:mm[:ss]` stamp — an absent age, never a guessed one.
///
/// Wall-clock convention, the one PT and FR already follow (#4189): the
/// provider's own fields are kept as-is, with no timezone conversion. FR's
/// `*_maj` stamps carry an explicit offset, which `DateTime.tryParse`
/// honours; PT's `DataAtualizacao` ("2026-06-08 13:15") carries none and
/// `DateTime.tryParse` yields a local DateTime holding those wall-clock
/// fields (`portugal_merged_row.dart`). MIMIT stamps carry no offset
/// either, so they get exactly PT's treatment.
DateTime? parseMiseDtComu(String? raw) {
  final m = _dtComu.firstMatch(raw?.trim() ?? '');
  if (m == null) return null;
  int g(int i) => int.parse(m.group(i) ?? '0');
  final value = DateTime(g(3), g(2), g(1), g(4), g(5), g(6));
  // `DateTime` rolls an out-of-range field over (31/02 → 03/03); a stamp
  // that does not survive the round trip is malformed, not a date.
  final valid = value.year == g(3) &&
      value.month == g(2) &&
      value.day == g(1) &&
      value.hour == g(4) &&
      value.minute == g(5) &&
      value.second == g(6);
  return valid ? value : null;
}

final RegExp _dtComu =
    RegExp(r'^(\d{2})/(\d{2})/(\d{4}) (\d{2}):(\d{2})(?::(\d{2}))?$');

class MisePriceData {
  double? benzinaSelf;
  double? benzinaServed;
  // #3188 — premium grades carried separately so they surface as e98 /
  // dieselPremium instead of polluting (or being dropped from) the regular
  // slots.
  double? benzinaPremiumSelf;
  double? benzinaPremiumServed;
  double? gasolioSelf;
  double? gasolioServed;
  double? gasolioPremiumSelf;
  double? gasolioPremiumServed;
  double? gpl;
  double? metano;

  /// The freshest `dtComu` as the user reads it: `dd/MM HH:mm`.
  /// **Display only** — the freshness gate reads [priceUpdatedAt] (#4189).
  String? updatedAt;

  /// The freshest raw `dtComu` stamp, as MIMIT sent it (#4309). Persisted
  /// under its own key; a dataset written before #4309 lacks it and reads
  /// back as null, so [priceUpdatedAt] is null until the next download.
  String? updatedAtRaw;

  /// [updatedAtRaw] as a real instant — see [parseMiseDtComu].
  DateTime? get priceUpdatedAt => parseMiseDtComu(updatedAtRaw);

  MisePriceData();

  Map<String, dynamic> toJson() => {
        if (benzinaSelf != null) 'bs': benzinaSelf,
        if (benzinaServed != null) 'bv': benzinaServed,
        if (benzinaPremiumSelf != null) 'bps': benzinaPremiumSelf,
        if (benzinaPremiumServed != null) 'bpv': benzinaPremiumServed,
        if (gasolioSelf != null) 'gs': gasolioSelf,
        if (gasolioServed != null) 'gv': gasolioServed,
        if (gasolioPremiumSelf != null) 'gps': gasolioPremiumSelf,
        if (gasolioPremiumServed != null) 'gpv': gasolioPremiumServed,
        if (gpl != null) 'gp': gpl,
        if (metano != null) 'me': metano,
        if (updatedAt != null) 'u': updatedAt,
        if (updatedAtRaw != null) 'ur': updatedAtRaw,
      };

  factory MisePriceData.fromJson(Map<String, dynamic> j) => MisePriceData()
    ..benzinaSelf = (j['bs'] as num?)?.toDouble()
    ..benzinaServed = (j['bv'] as num?)?.toDouble()
    ..benzinaPremiumSelf = (j['bps'] as num?)?.toDouble()
    ..benzinaPremiumServed = (j['bpv'] as num?)?.toDouble()
    ..gasolioSelf = (j['gs'] as num?)?.toDouble()
    ..gasolioServed = (j['gv'] as num?)?.toDouble()
    ..gasolioPremiumSelf = (j['gps'] as num?)?.toDouble()
    ..gasolioPremiumServed = (j['gpv'] as num?)?.toDouble()
    ..gpl = (j['gp'] as num?)?.toDouble()
    ..metano = (j['me'] as num?)?.toDouble()
    ..updatedAt = j['u'] as String?
    ..updatedAtRaw = j['ur'] as String?;
}
