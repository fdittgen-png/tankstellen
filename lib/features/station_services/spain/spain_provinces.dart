// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../core/utils/geo_utils.dart';

/// Approximate centre (capital-city coordinates) of each Spanish province,
/// keyed by MITECO `IDProvincia`. Used to map a search point to the
/// province(s) whose stations to fetch (#2264).
///
/// Extracted from `miteco_station_service.dart` so the province-keying +
/// multi-province merge fix keeps the service file under the length norm.
const Map<String, (double lat, double lng)> spainProvinceCenters = {
  '01': (42.8467, -2.6727), // Álava
  '02': (38.9943, -1.8585), // Albacete
  '03': (38.3452, -0.4810), // Alicante
  '04': (36.8340, -2.4637), // Almería
  '05': (40.6565, -4.6818), // Ávila
  '06': (38.8794, -6.9707), // Badajoz
  '07': (39.5696, 2.6502), // Baleares
  '08': (41.3851, 2.1734), // Barcelona
  '09': (42.3440, -3.6970), // Burgos
  '10': (39.4753, -6.3724), // Cáceres
  '11': (36.5271, -6.2886), // Cádiz
  '12': (39.9864, -0.0513), // Castellón
  '13': (38.9860, -3.9273), // Ciudad Real
  '14': (37.8882, -4.7794), // Córdoba
  '15': (43.3623, -8.4115), // A Coruña
  '16': (40.0704, -2.1374), // Cuenca
  '17': (41.9794, 2.8214), // Girona
  '18': (37.1773, -3.5986), // Granada
  '19': (40.6337, -3.1660), // Guadalajara
  '20': (43.3183, -1.9812), // Guipúzcoa
  '21': (37.2614, -6.9447), // Huelva
  '22': (42.1318, -0.4078), // Huesca
  '23': (37.7796, -3.7849), // Jaén
  '24': (42.5987, -5.5671), // León
  '25': (41.6176, 0.6200), // Lleida
  '26': (42.4650, -2.4500), // La Rioja
  '27': (43.0099, -7.5562), // Lugo
  '28': (40.4168, -3.7038), // Madrid
  '29': (36.7213, -4.4214), // Málaga
  '30': (37.9922, -1.1307), // Murcia
  '31': (42.8125, -1.6458), // Navarra
  '32': (42.3358, -7.8639), // Ourense
  '33': (43.3619, -5.8494), // Asturias
  '34': (42.0097, -4.5288), // Palencia
  '35': (28.1235, -15.4363), // Las Palmas
  '36': (42.4310, -8.6446), // Pontevedra
  '37': (40.9701, -5.6635), // Salamanca
  '38': (28.4636, -16.2518), // S/C de Tenerife
  '39': (43.4623, -3.8100), // Cantabria
  '40': (40.9429, -4.1088), // Segovia
  '41': (37.3891, -5.9845), // Sevilla
  '42': (41.7636, -2.4649), // Soria
  '43': (41.1189, 1.2445), // Tarragona
  '44': (40.3456, -1.1065), // Teruel
  '45': (39.8628, -4.0273), // Toledo
  '46': (39.4699, -0.3763), // Valencia
  '47': (41.6523, -4.7245), // Valladolid
  '48': (43.2630, -2.9350), // Vizcaya
  '49': (41.5033, -5.7446), // Zamora
  '50': (41.6488, -0.8891), // Zaragoza
  '51': (35.8894, -5.3213), // Ceuta
  '52': (35.2923, -2.9381), // Melilla
};

/// MITECO has no coordinate/radius search — only per-province. A search point
/// near a province border (or with a large radius) overlaps several
/// provinces, so the service must fetch + merge each (#2264).
///
/// Returns the province ids whose centre is within `[radiusKm] + [marginKm]`
/// of ([lat], [lng]), always including the single nearest province so a search
/// deep inside one province still resolves. [marginKm] (default 60 km, roughly
/// a province half-width) absorbs the centre-vs-border approximation so a
/// station physically nearby but administratively in the neighbour is not
/// missed.
List<String> spainProvincesNear(
  double lat,
  double lng,
  double radiusKm, {
  double marginKm = 60,
}) {
  var nearestId = '28'; // Madrid fallback
  var nearestDist = double.infinity;
  final within = <String>[];

  for (final entry in spainProvinceCenters.entries) {
    final d = distanceKm(lat, lng, entry.value.$1, entry.value.$2);
    if (d < nearestDist) {
      nearestDist = d;
      nearestId = entry.key;
    }
    if (d <= radiusKm + marginKm) within.add(entry.key);
  }

  if (!within.contains(nearestId)) within.add(nearestId);
  return within;
}
