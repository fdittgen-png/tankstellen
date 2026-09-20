// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/storage/hive_deferred_user_boxes.dart';
import 'package:tankstellen/core/widgets/deferred_user_boxes_gate.dart';

import '../../helpers/hive_temp_dir.dart';

/// #4318 — the privacy dashboard reads the deferred price-history box
/// synchronously; its route waits for the box without flashing a loader
/// on the normal path.
void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('deferred_gate_');
    Hive.init(dir.path);
    HiveDeferredUserBoxes.resetForTest();
  });

  tearDown(() async {
    HiveDeferredUserBoxes.resetForTest();
    await closeHiveAndDeleteTemp(dir);
  });

  const child = Text('dashboard', textDirection: TextDirection.ltr);

  testWidgets('boxes already open → the screen on the very first frame',
      (tester) async {
    await tester.runAsync(() => Hive.openBox<dynamic>(HiveBoxes.priceHistory));
    HiveDeferredUserBoxes.arm(null);

    await tester.pumpWidget(
        const MaterialApp(home: DeferredUserBoxesGate(child: child)));
    expect(find.text('dashboard'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('box still opening → held until the open settles, then the '
      'screen', (tester) async {
    final opened = Completer<Box<dynamic>>();
    HiveDeferredUserBoxes.arm(null);
    HiveDeferredUserBoxes.opener = (name, cipher) => opened.future;

    await tester.pumpWidget(
        const MaterialApp(home: DeferredUserBoxesGate(child: child)));
    expect(find.text('dashboard'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.runAsync(() async => opened
        .complete(await Hive.openBox<dynamic>(HiveBoxes.priceHistory)));
    await tester.pump();
    await tester.pump();
    expect(find.text('dashboard'), findsOneWidget);
  });
}
