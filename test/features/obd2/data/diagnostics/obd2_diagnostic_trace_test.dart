// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/diagnostics/obd2_diagnostic_recordings.dart';
import 'package:tankstellen/features/obd2/data/diagnostics/obd2_diagnostic_trace.dart';

import '../../../../helpers/silence_error_logger.dart';

/// #4548 — the raw per-command trace file.
void main() {
  silenceErrorLoggerSpool();
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('obd2diag');
  });
  tearDown(() async {
    await Obd2DiagnosticTrace.end();
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  List<Map<String, dynamic>> lines(File f) => [
        for (final l in const LineSplitter().convert(f.readAsStringSync()))
          jsonDecode(l) as Map<String, dynamic>,
      ];

  test('header, one cmd line per reply and per error, end mark', () async {
    var clock = DateTime.utc(2026, 10, 31, 8, 15);
    final trace = (await Obd2DiagnosticTrace.begin(
      header: {'vehicle': {'make': 'Peugeot'}},
      directory: dir,
      now: () => clock,
    ))!;
    expect(Obd2DiagnosticTrace.current, same(trace));
    final reply = Completer<String>();
    final pending = trace.observe('010C', reply.future);
    clock = clock.add(const Duration(milliseconds: 42));
    reply.complete('41 0C 1A F8\r>');
    expect(await pending, '41 0C 1A F8\r>');
    await expectLater(
        trace.observe('0142', Future<String>.error(TimeoutException('x'))),
        throwsA(isA<TimeoutException>()));
    await Obd2DiagnosticTrace.end();
    expect(Obd2DiagnosticTrace.current, isNull);

    expect(trace.file.uri.pathSegments.last,
        'obd2-diagnostic-20261031T081500Z.ndjson');
    final l = lines(trace.file);
    expect(l.first['k'], 'header');
    expect(l.first['vehicle'], {'make': 'Peugeot'});
    expect(l[1], containsPair('c', '010C'));
    expect(l[1], containsPair('r', '41 0C 1A F8'));
    expect(l[1], containsPair('ms', 42));
    expect(l[2], containsPair('e', 'TimeoutException'));
    expect(l.last['p'], 'end');
  });

  test('a DTC reply becomes a decoded dtc mark only when the set changes',
      () async {
    final trace = (await Obd2DiagnosticTrace.begin(header: {}, directory: dir))!;
    await trace.observe('03', Future.value('43 01 07 30>'));
    await trace.observe('03', Future.value('43 01 07 30>'));
    await trace.observe('03', Future.value('43 00>'));
    await Obd2DiagnosticTrace.end();
    final marks = lines(trace.file).where((m) => m['p'] == 'dtc').toList();
    expect(marks.map((m) => m['codes']), [
      ['P0730'],
      <String>[],
    ]);
  });

  test('retention keeps the newest recordings', () async {
    for (var i = 0; i < Obd2DiagnosticRecordings.keepNewest + 3; i++) {
      File('${dir.path}/${Obd2DiagnosticRecordings.fileNameFor(DateTime.utc(2026, 1, 1).add(Duration(hours: i)))}')
          .writeAsStringSync('{}');
    }
    File('${dir.path}/unrelated.txt').writeAsStringSync('keep me');
    await Obd2DiagnosticRecordings.prune(dir);
    final left = await Obd2DiagnosticRecordings.list(dir);
    expect(left, hasLength(Obd2DiagnosticRecordings.keepNewest - 1));
    expect(left.first.startedAt, DateTime.utc(2026, 1, 1).add(const Duration(hours: 22)));
    expect(File('${dir.path}/unrelated.txt').existsSync(), isTrue);
  });

  test('a directory that cannot be written yields no trace, never a throw',
      () async {
    final missing = Directory('${dir.path}/gone');
    await expectLater(
        Obd2DiagnosticTrace.begin(header: {}, directory: missing), completion(isNull));
    expect(Obd2DiagnosticTrace.current, isNull);
  });
}
