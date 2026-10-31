// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'CI adapter follows exports and shares that graph with coverage',
    () async {
      final adapter = File('tool/ci_selection.dart').absolute.path;
      final tmp = Directory.systemTemp.createTempSync('ci_exports_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      void write(String path, String content) {
        final file = File('${tmp.path}/$path');
        file.parent.createSync(recursive: true);
        file.writeAsStringSync(content);
      }

      write('lib/api.dart', "export 'value.dart';\n");
      write('lib/value.dart', 'int value() => 2;\n');
      write('test/api_test.dart', "import '../lib/api.dart';\n");
      write('test/other_test.dart', "import '../lib/other.dart';\n");
      write('lib/other.dart', 'int other() => 1;\n');
      write('test/lint/contract_test.dart', "import 'dart:io';\n");
      write('paths.json', jsonEncode(['lib/value.dart']));
      write('lines.diff', '''diff --git a/lib/value.dart b/lib/value.dart
--- a/lib/value.dart
+++ b/lib/value.dart
@@ -1 +1 @@
-int value() => 1;
+int value() => 2;
''');
      final result = await Process.run('dart', [
        adapter,
        'paths.json',
        'lines.diff',
      ], workingDirectory: tmp.path);
      expect(result.exitCode, 0, reason: '${result.stderr}');
      final selection = jsonDecode('${result.stdout}') as Map<String, dynamic>;
      expect(selection['tests'], [
        'test/api_test.dart',
        'test/lint/contract_test.dart',
      ]);
      expect(selection['coverage_tests'], ['test/api_test.dart']);
      expect(selection['applicable'], isTrue);
    },
  );
}
