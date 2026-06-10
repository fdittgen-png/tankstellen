// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Raw CSV row + merge accumulator for the Argentina open-data service —
/// extracted from `argentina_station_service.dart` to keep that file under
/// the 400-line cap (#1680).
library;

class ArgentinaRawStation {
  final String empresa;
  final String direccion;
  final String localidad;
  final String provincia;
  final String producto;
  final double precio;
  final String fechaVigencia;
  final String bandera;
  final double lat;
  final double lng;

  /// #3196 — CSV col 11 (`tipohorario`: "Diurno"/"Nocturno"), lowercased.
  /// The merge prefers diurno (daytime pump price) rows.
  final String tipoHorario;

  const ArgentinaRawStation({
    required this.empresa,
    required this.direccion,
    required this.localidad,
    required this.provincia,
    required this.producto,
    required this.precio,
    required this.fechaVigencia,
    required this.bandera,
    required this.lat,
    required this.lng,
    this.tipoHorario = '',
  });

  /// #2264 — compact JSON for the persisted dataset (single-letter keys keep
  /// the ~700 KB national CSV's Hive footprint down).
  Map<String, dynamic> toJson() => {
        'e': empresa,
        'd': direccion,
        'l': localidad,
        'pv': provincia,
        'pr': producto,
        'p': precio,
        'f': fechaVigencia,
        'b': bandera,
        'la': lat,
        'lo': lng,
        'th': tipoHorario,
      };

  factory ArgentinaRawStation.fromJson(Map<String, dynamic> j) => ArgentinaRawStation(
        empresa: j['e'] as String? ?? '',
        direccion: j['d'] as String? ?? '',
        localidad: j['l'] as String? ?? '',
        provincia: j['pv'] as String? ?? '',
        producto: j['pr'] as String? ?? '',
        precio: (j['p'] as num?)?.toDouble() ?? 0,
        fechaVigencia: j['f'] as String? ?? '',
        bandera: j['b'] as String? ?? '',
        lat: (j['la'] as num?)?.toDouble() ?? 0,
        lng: (j['lo'] as num?)?.toDouble() ?? 0,
        tipoHorario: j['th'] as String? ?? '',
      );
}

class ArgentinaMergedStation {
  final ArgentinaRawStation raw;
  final double dist;
  double? naftaRegular;
  double? naftaPremium;
  double? dieselRegular;
  double? dieselPremium;
  double? gnc;

  ArgentinaMergedStation({required this.raw, required this.dist});
}
