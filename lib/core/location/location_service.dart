import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../error/exceptions.dart';
import 'geolocator_wrapper.dart';

part 'location_service.g.dart';

@riverpod
LocationService locationService(Ref ref) {
  return LocationService(ref.watch(geolocatorWrapperProvider));
}

class LocationService {
  final GeolocatorWrapper _geolocator;

  LocationService(this._geolocator);

  Future<Position> getCurrentPosition() async {
    final bool serviceEnabled = await _geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        message: 'Standortdienste sind deaktiviert.',
      );
    }

    LocationPermission permission = await _geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationException(
          message: 'Standortberechtigung wurde verweigert.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        message:
            'Location permission permanently denied. '
            'Please enable it in Settings.',
      );
    }

    return await _geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  double distanceBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return _geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
}
