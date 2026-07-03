// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// Flutter-drive driver for the App Store screenshot generator
// (integration_test/appstore_screenshots_test.dart). Each
// `binding.takeScreenshot('<name>')` call in the test is delivered here and
// written to build/appstore_screenshots/<name>.png at the simulator's native
// resolution (iPhone 17 Pro Max = 1320×2868 = the App Store 6.9" iPhone slot).
//
//   flutter drive \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/appstore_screenshots_test.dart \
//     -d <iphone-17-pro-max-sim-udid>
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot:
        (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      final file = File('build/appstore_screenshots/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      stdout.writeln('saved screenshot: ${file.path} (${bytes.length} bytes)');
      return true;
    },
  );
}
