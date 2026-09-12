// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import '../domain/ev/charging_station.dart';
import '../domain/fuel_type.dart';
import 'app_routes.dart';

/// Round-trips every typed `extra` payload through state restoration
/// (#4061).
///
/// go_router serialises a route's `extra` to JSON when Android saves the
/// route stack and decodes it to a plain `Map` on restore — or to `null`
/// when the object is not JSON-encodable. Without a codec, every typed
/// payload in [AppRoute] came back wrong after a low-memory kill: the
/// `ChargingStation` behind `/ev-station` arrived as a `Map` (a red
/// screen, #4052), and the [AddFillUpRoute] pre-fill arrived as `null`,
/// silently opening the bare form on a user mid-way through a fill-up.
/// The device behind the 2026-09-11 export was killed 34 times in three
/// days; this is not an edge case.
///
/// One codec on the router fixes the class. Primitives pass through
/// untouched (they were never the problem); each typed payload is tagged
/// so the decoder can rebuild the same type the sender used. An object
/// the codec does not know is encoded as `null`, exactly what go_router
/// did before — nothing gets worse, and the tests below pin what gets
/// better.
class AppRouteExtraCodec extends Codec<Object?, Object?> {
  const AppRouteExtraCodec();

  static const _tag = '@extra';
  static const _chargingStation = 'ChargingStation';
  static const _addFillUp = 'AddFillUpRoute';

  @override
  Converter<Object?, Object?> get encoder => const _Encoder();

  @override
  Converter<Object?, Object?> get decoder => const _Decoder();
}

class _Encoder extends Converter<Object?, Object?> {
  const _Encoder();

  @override
  Object? convert(Object? input) {
    if (input == null ||
        input is String ||
        input is num ||
        input is bool ||
        input is List ||
        input is Map) {
      // Already JSON-shaped: not ours to interpret, and never was.
      return input;
    }
    if (input is ChargingStation) {
      return {
        AppRouteExtraCodec._tag: AppRouteExtraCodec._chargingStation,
        'v': input.toJson(),
      };
    }
    if (input is AddFillUpRoute) {
      return {
        AppRouteExtraCodec._tag: AppRouteExtraCodec._addFillUp,
        'stationId': input.stationId,
        'stationName': input.stationName,
        'fuelType': input.fuelType?.name,
        'pricePerLiter': input.pricePerLiter,
      };
    }
    // Unknown payload: the pre-codec behaviour, made explicit.
    return null;
  }
}

class _Decoder extends Converter<Object?, Object?> {
  const _Decoder();

  @override
  Object? convert(Object? input) {
    if (input is! Map) return input;
    final tag = input[AppRouteExtraCodec._tag];
    if (tag == null) return input;
    try {
      switch (tag) {
        case AppRouteExtraCodec._chargingStation:
          final v = input['v'];
          if (v is! Map) return null;
          return ChargingStation.fromJson(Map<String, dynamic>.from(v));
        case AppRouteExtraCodec._addFillUp:
          final fuel = input['fuelType'];
          return AddFillUpRoute(
            stationId: input['stationId'] as String?,
            stationName: input['stationName'] as String?,
            fuelType: fuel is String ? FuelType.fromString(fuel) : null,
            pricePerLiter: (input['pricePerLiter'] as num?)?.toDouble(),
          );
      }
    } on Object {
      // A payload that no longer decodes is a null extra — the route
      // builders already treat that as "open without a pre-fill".
      return null;
    }
    return null;
  }
}
