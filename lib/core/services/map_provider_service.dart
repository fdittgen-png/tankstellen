import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'impl/flutter_map_provider.dart';
import 'map_provider.dart';

part 'map_provider_service.g.dart';

/// Provides the active [MapProvider] implementation.
///
/// Currently always returns [FlutterMapProvider] (OpenStreetMap).
/// A future version could check user settings (e.g. a Google Maps API key)
/// and return a different implementation accordingly.
@Riverpod(keepAlive: true)
MapProvider mapProvider(Ref ref) {
  return const FlutterMapProvider();
}
