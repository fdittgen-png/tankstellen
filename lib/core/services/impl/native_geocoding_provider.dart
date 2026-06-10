// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geo;
import '../../error/exceptions.dart';
import '../../network/dio_offline.dart';
import '../../telemetry/collectors/breadcrumb_collector.dart';
import '../geocoding_provider.dart';
import '../service_result.dart';
import '../../../core/logging/error_logger.dart';

/// Geocoding via native platform APIs (Android/iOS only).
/// Uses the `geocoding` package which wraps platform geocoders.
/// Country-aware: passes the correct country name for ZIP resolution.
class NativeGeocodingProvider implements GeocodingProvider {
  final String _countryName;

  NativeGeocodingProvider({String countryName = 'Deutschland'})
      : _countryName = countryName;

  @override
  ServiceSource get source => ServiceSource.nativeGeocoding;

  @override
  bool get isAvailable {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  @override
  Future<({double lat, double lng})> zipCodeToCoordinates(
    String zipCode, {
    CancelToken? cancelToken,
  }) async {
    try {
      final locations = await geo.locationFromAddress(
        '$zipCode, $_countryName',
      );
      if (locations.isEmpty) {
        throw LocationException(
          message: 'Keine Koordinaten für PLZ $zipCode gefunden.',
        );
      }
      final location = locations.first;
      return (lat: location.latitude, lng: location.longitude);
    } catch (e, st) { // ignore: unused_catch_stack
      if (e is LocationException) rethrow;
      throw LocationException(
        message: 'Geräte-Geocodierung fehlgeschlagen: $e',
      );
    }
  }

  @override
  Future<String?> coordinatesToCountryCode(
    double lat, double lng, {
    CancelToken? cancelToken,
  }) async {
    if (!isAvailable) return null;
    try {
      final placemarks = await geo.placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;
      return placemarks.first.isoCountryCode;
    } on Exception catch (e, st) {
      // #2745 — the on-device geocoder raises `PlatformException(IO_ERROR,
      // …UNAVAILABLE…)` when its backend can't be reached offline (field
      // trace #7). This already falls back to Nominatim, so drop the
      // expected offline failure to a breadcrumb rather than an ERROR trace.
      // A genuine native-geocoder fault still ERROR-logs.
      if (isOfflineError(e)) {
        // #3145 — coords bucketed to 1 decimal: triage never needs more.
        BreadcrumbCollector.add(
          'Native country detection skipped — offline',
          detail: 'lat=${lat.toStringAsFixed(1)} '
              'lng=${lng.toStringAsFixed(1)} type=${e.runtimeType}',
        );
        return null;
      }
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'Native country detection failed'}));
      return null;
    }
  }

  @override
  Future<String> coordinatesToAddress(
    double lat, double lng, {
    CancelToken? cancelToken,
  }) async {
    try {
      final placemarks = await geo.placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return '$lat, $lng';
      final place = placemarks.first;
      return [place.postalCode, place.locality]
          .where((s) => s != null && s.isNotEmpty)
          .join(' ');
    } on Exception catch (e, st) {
      // #2745 — see [coordinatesToCountryCode]: an offline platform-geocoder
      // failure is expected (falls back to "lat, lng"), so breadcrumb it
      // rather than ERROR-log. A genuine fault still persists.
      if (isOfflineError(e)) {
        // #3145 — coords bucketed to 1 decimal: triage never needs more.
        BreadcrumbCollector.add(
          'Native reverse geocoding skipped — offline',
          detail: 'lat=${lat.toStringAsFixed(1)} '
              'lng=${lng.toStringAsFixed(1)} type=${e.runtimeType}',
        );
        return '$lat, $lng';
      }
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'Native reverse geocoding failed'}));
      return '$lat, $lng';
    }
  }
}
