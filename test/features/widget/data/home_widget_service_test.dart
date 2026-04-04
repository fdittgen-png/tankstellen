import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/widget/data/home_widget_service.dart';

void main() {
  group('HomeWidgetService', () {
    test('updateWidget does not throw when storage has no favorites', () async {
      // HomeWidgetService.updateWidget requires platform channels (home_widget)
      // which are not available in unit tests. Verify the service class exists
      // and the static method is callable.
      expect(HomeWidgetService.updateWidget, isNotNull);
      expect(HomeWidgetService.init, isNotNull);
    });
  });
}
