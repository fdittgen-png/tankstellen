// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Merge accumulator for the DGEG `PesquisarPostos` rows — extracted from
/// `portugal_station_service.dart` to keep that file under the 400-line cap
/// (#1680).
library;

/// Mutable accumulator used while merging DGEG rows for the same
/// station Id across fuel types.
class PortugalMergedRow {
  final int id;
  final String name;
  final String brand;
  final String street;
  final String postCode;
  final String place;
  final double lat;
  final double lng;

  double? gasolina95;
  double? gasolina98;
  double? gasoleo;
  double? gpl;
  String? rawUpdatedAt;

  PortugalMergedRow({
    required this.id,
    required this.name,
    required this.brand,
    required this.street,
    required this.postCode,
    required this.place,
    required this.lat,
    required this.lng,
  });

  void assignPrice(String fuelLabel, double? price) {
    if (price == null) return;
    final label = fuelLabel.toLowerCase();
    // #3196 — an "especial" (additive premium) grade must never overwrite
    // its plain sibling of the same octane: the live feed lists
    // 'Gasolina especial 95' right after 'Gasolina simples 95' for the
    // same station, and a last-wins assignment stamped the premium price
    // into the regular slot. Especial fills the slot only when no plain
    // row exists; a plain row always wins.
    final isEspecial = label.contains('especial');
    // Order matters: check "98" before the generic "95" contains check.
    if (label.contains('98')) {
      if (isEspecial) {
        gasolina98 ??= price;
      } else {
        gasolina98 = price;
      }
    } else if (label.contains('95')) {
      if (isEspecial) {
        gasolina95 ??= price;
      } else {
        gasolina95 = price;
      }
    } else if (label.contains('gasóleo') ||
        label.contains('gasoleo') ||
        label.contains('diesel')) {
      if (isEspecial) {
        gasoleo ??= price;
      } else {
        gasoleo = price;
      }
    } else if (label.contains('gpl')) {
      gpl = price;
    }
  }

  /// #3196 — keep the freshest `DataAtualizacao` across the station's fuel
  /// rows. The DGEG format ("2026-06-08 10:30") sorts lexicographically.
  void noteUpdatedAt(String? raw) {
    if (raw == null || raw.trim().isEmpty) return;
    final value = raw.trim();
    if (rawUpdatedAt == null || value.compareTo(rawUpdatedAt!) > 0) {
      rawUpdatedAt = value;
    }
  }

  /// "2026-06-08 10:30" → "08/06 10:30" (the dd/MM HH:mm convention the
  /// other country services use for [Station.updatedAt]).
  String? get formattedUpdatedAt {
    final raw = rawUpdatedAt;
    if (raw == null) return null;
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}:\d{2})').firstMatch(raw);
    if (m == null) return raw;
    return '${m.group(3)}/${m.group(2)} ${m.group(4)}';
  }
}
