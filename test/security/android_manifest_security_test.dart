// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AndroidManifest security', () {
    late String manifestContent;

    setUp(() {
      final manifestFile = File(
        'android/app/src/main/AndroidManifest.xml',
      );
      expect(manifestFile.existsSync(), isTrue,
          reason: 'AndroidManifest.xml must exist');
      manifestContent = manifestFile.readAsStringSync();
    });

    test('widget receiver has BIND_APPWIDGET permission', () {
      // The FuelPriceWidgetProvider receiver must require BIND_APPWIDGET
      // to prevent arbitrary apps from triggering widget updates.
      final receiverPattern = RegExp(
        r'<receiver[^>]*android:name="\.FuelPriceWidgetProvider"[^>]*>',
        dotAll: true,
      );

      final match = receiverPattern.firstMatch(manifestContent);
      expect(match, isNotNull,
          reason: 'FuelPriceWidgetProvider receiver must exist in manifest');

      final receiverTag = match!.group(0)!;
      expect(
        receiverTag,
        contains('android.permission.BIND_APPWIDGET'),
        reason:
            'Widget receiver must require BIND_APPWIDGET permission to prevent '
            'unauthorized apps from triggering widget updates',
      );
    });

    test('CarAppService — when active — has permission restriction', () {
      // While Google Play's Foreground Service Use form is unapproved
      // (#1498), the TankstellenCarAppService entry is commented out so
      // the AAB ships without foreground-service permissions. Skip the
      // restriction check when the service is absent, but enforce it the
      // moment the entry is restored.
      final stripped =
          manifestContent.replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');
      final servicePattern = RegExp(
        r'<service[^>]*android:name="\.TankstellenCarAppService"[^>]*>',
        dotAll: true,
      );

      final match = servicePattern.firstMatch(stripped);
      if (match == null) {
        // Service entry is currently commented out — verify it's actually
        // commented (not silently deleted) so the restore path stays valid.
        expect(
          manifestContent,
          contains('TankstellenCarAppService'),
          reason:
              'TankstellenCarAppService must remain in the manifest, even '
              'if commented out, so the post-FS-form restore is a single '
              'block uncomment.',
        );
        return;
      }

      final serviceTag = match.group(0)!;
      expect(
        serviceTag,
        contains('android:permission='),
        reason:
            'CarAppService must have a permission attribute to restrict binding',
      );
    });

    test('no exported components without permission restriction', () {
      // Every exported receiver and service (except the main activity)
      // must have a permission attribute to prevent unauthorized access.
      final exportedPattern = RegExp(
        r'<(receiver|service)[^>]*android:exported="true"[^>]*>',
        dotAll: true,
      );

      final matches = exportedPattern.allMatches(manifestContent);
      final violations = <String>[];

      for (final match in matches) {
        final tag = match.group(0)!;
        if (!tag.contains('android:permission=')) {
          // Extract the component name for the error message
          final nameMatch =
              RegExp(r'android:name="([^"]+)"').firstMatch(tag);
          final name = nameMatch?.group(1) ?? 'unknown';
          violations.add('$name is exported without permission restriction');
        }
      }

      if (violations.isNotEmpty) {
        fail(
          'Found exported components without permission restrictions:\n'
          '${violations.join('\n')}\n\n'
          'All exported receivers and services must have an '
          'android:permission attribute.',
        );
      }
    });
  });
}
