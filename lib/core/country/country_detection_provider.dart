import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../location/user_position_provider.dart';
import '../services/service_providers.dart';

part 'country_detection_provider.g.dart';

/// Detects the user's country from their GPS position via reverse geocoding.
/// Watches [userPositionProvider] and updates when position changes.
@Riverpod(keepAlive: true)
class DetectedCountry extends _$DetectedCountry {
  bool _detecting = false;

  @override
  String? build() {
    final position = ref.watch(userPositionProvider);
    if (position != null) {
      _detectCountry(position.lat, position.lng);
    }
    return null;
  }

  Future<void> _detectCountry(double lat, double lng) async {
    if (_detecting) return;
    _detecting = true;
    try {
      final geocoding = ref.read(geocodingChainProvider);
      final code = await geocoding.coordinatesToCountryCode(lat, lng);
      if (code != null && code != state) {
        state = code;
      }
    } finally {
      _detecting = false;
    }
  }
}
