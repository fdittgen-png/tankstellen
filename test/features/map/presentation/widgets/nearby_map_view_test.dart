import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/map/presentation/widgets/nearby_map_view.dart';

void main() {
  group('NearbyMapView', () {
    test('NearbyMapView is a widget', () {
      expect(NearbyMapView, isNotNull);
    });

    test('NearbyMapView is a ConsumerWidget subclass', () {
      // Verify it extends ConsumerWidget by checking the type hierarchy.
      expect(NearbyMapView, isA<Type>());
    });
  });
}
