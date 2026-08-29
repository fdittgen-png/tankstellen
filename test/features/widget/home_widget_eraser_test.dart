// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3867 (Epic #3865) — the home-screen widget container is outside Hive;
// the eraser's key list must cover every key the widget writers use, or a
// "deleted" device keeps the user's last position in the widget store.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/widget/data/home_widget_eraser.dart';

void main() {
  test('every saveWidgetData key in the widget writers is erased', () {
    final keyRe = RegExp(r"saveWidgetData(?:<[^>]+>)?\(\s*'([a-z_]+)'");
    final written = <String>{};
    for (final dir in ['lib/features/widget', 'lib/features/car']) {
      for (final f in Directory(dir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        for (final m in keyRe.allMatches(f.readAsStringSync())) {
          written.add(m.group(1)!);
        }
      }
    }
    expect(written, isNotEmpty);
    final missing = written.difference(kHomeWidgetDataKeys.toSet());
    expect(missing, isEmpty,
        reason: 'widget data key(s) never erased: $missing — add them to '
            'kHomeWidgetDataKeys');
  });

  test('clearHomeWidgetData never throws without a widget host', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await expectLater(clearHomeWidgetData(), completes);
  });
}
