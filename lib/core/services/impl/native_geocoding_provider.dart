import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geo;
import '../../error/exceptions.dart';
import '../geocoding_provider.dart';
import '../service_result.dart';

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
    } catch (e) {
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
    } on Exception catch (e) {
      debugPrint('Native country detection failed: $e');
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
    } on Exception catch (e) {
      debugPrint('Native reverse geocoding failed: $e');
      return '$lat, $lng';
    }
  }
}
