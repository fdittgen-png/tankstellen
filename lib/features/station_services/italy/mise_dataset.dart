// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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
  String? updatedAt;

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
    ..updatedAt = j['u'] as String?;
}
