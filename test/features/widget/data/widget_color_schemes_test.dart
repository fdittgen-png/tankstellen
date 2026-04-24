import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/widget/data/widget_color_schemes.dart';

void main() {
  group('widgetColorSchemes', () {
    test('exposes the six expected identifiers', () {
      expect(widgetColorSchemes, hasLength(6));
      expect(
        widgetColorSchemes,
        containsAll(<String>[
          'system',
          'light',
          'dark',
          'blue',
          'green',
          'orange',
        ]),
      );
    });

    test('defaultWidgetColorScheme is one of the advertised schemes', () {
      expect(widgetColorSchemes, contains(defaultWidgetColorScheme));
    });
  });
}
