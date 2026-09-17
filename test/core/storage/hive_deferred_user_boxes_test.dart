// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/core/storage/hive_deferred_user_boxes.dart';
import 'package:tankstellen/core/storage/hive_open_timing.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';

/// #4318 — `priceHistory` left the first-frame batch. These tests RUN the
/// deferred open against real Hive files: single-flight under a race, the
/// armed key, per-box timing, and a genuinely corrupt file.
class _CapturingRecorder implements TraceRecorder {
  final captured = <ContextualError>[];

  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    ServiceChainSnapshot? serviceChainState,
  }) async {
    if (error is ContextualError) captured.add(error);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Standard CRC-32 — the checksum Hive stamps on every frame.
int _crc32(List<int> bytes) {
  var crc = 0xffffffff;
  for (final b in bytes) {
    crc ^= b;
    for (var k = 0; k < 8; k++) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xedb88320 : crc >> 1;
    }
  }
  return crc ^ 0xffffffff;
}

/// One Hive frame with a valid checksum: `[length][key][value][crc]`.
/// A bad checksum is what Hive's crash recovery silently truncates; a
/// frame whose checksum is RIGHT but whose content cannot be read is the
/// damage recovery cannot absorb — `openBox` throws a HiveError.
Uint8List _frame(String key, List<int> value) {
  final keyBytes = ascii.encode(key);
  final body = <int>[1, keyBytes.length, ...keyBytes, ...value];
  final length = 4 + body.length + 4;
  final head = ByteData(4)..setUint32(0, length, Endian.little);
  final withoutCrc = [...head.buffer.asUint8List(), ...body];
  final crc = ByteData(4)..setUint32(0, _crc32(withoutCrc), Endian.little);
  return Uint8List.fromList([...withoutCrc, ...crc.buffer.asUint8List()]);
}

List<int> _stringValue(String s) {
  final bytes = utf8.encode(s);
  final len = ByteData(4)..setUint32(0, bytes.length, Endian.little);
  return [4, ...len.buffer.asUint8List(), ...bytes];
}

void main() {
  late Directory dir;
  late _CapturingRecorder recorder;
  const box = HiveBoxes.priceHistory;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('deferred_user_boxes_');
    Hive.init(dir.path);
    HiveOpenTiming.reset();
    HiveDeferredUserBoxes.resetForTest();
    recorder = _CapturingRecorder();
    errorLogger.testRecorderOverride = recorder;
  });

  tearDown(() async {
    HiveDeferredUserBoxes.resetForTest();
    errorLogger.resetForTest();
    await Hive.close();
    dir.deleteSync(recursive: true);
  });

  test('manages priceHistory', () {
    expect(HiveDeferredUserBoxes.names, contains(HiveBoxes.priceHistory));
  });

  test('unarmed, it opens nothing and every gate passes', () async {
    await HiveDeferredUserBoxes.ensureOpen(box);
    expect(Hive.isBoxOpen(box), isFalse);
    expect(HiveDeferredUserBoxes.isReadable(box), isTrue);
  });

  test('armed, a closed box is not readable until it has opened — with the '
      'values already on disk', () async {
    final seeded = await Hive.openBox<dynamic>(box);
    await seeded.put('de-1', [
      {'e5': 1.9},
    ]);
    await seeded.close();

    HiveDeferredUserBoxes.arm(null);
    expect(HiveDeferredUserBoxes.isReadable(box), isFalse);

    await HiveDeferredUserBoxes.ensureOpen(box);
    expect(HiveDeferredUserBoxes.isReadable(box), isTrue);
    expect(Hive.box<dynamic>(box).get('de-1'), isNotEmpty);
  });

  test('the open uses the key HiveBoxes.init armed it with', () async {
    final cipher = HiveAesCipher(List<int>.generate(32, (i) => i));
    HiveAesCipher? used;
    HiveDeferredUserBoxes.arm(cipher);
    HiveDeferredUserBoxes.opener = (name, c) {
      used = c;
      return Hive.openBox<dynamic>(name, encryptionCipher: c);
    };
    await HiveDeferredUserBoxes.ensureOpen(box);
    expect(used, same(cipher));
  });

  test('race: simultaneous first-use callers share ONE open', () async {
    HiveDeferredUserBoxes.arm(null);
    final release = Completer<void>();
    var opens = 0;
    HiveDeferredUserBoxes.opener = (name, c) async {
      opens++;
      await release.future;
      return Hive.openBox<dynamic>(name, encryptionCipher: c);
    };

    final a = HiveDeferredUserBoxes.ensureOpen(box);
    final b = HiveDeferredUserBoxes.ensureOpen(box);
    final c = HiveDeferredUserBoxes.settled(box);
    expect(identical(a, b), isTrue, reason: 'the same future, not two opens');
    await pumpEventQueue();
    expect(opens, 1);
    expect(HiveDeferredUserBoxes.isReadable(box), isFalse);

    release.complete();
    await Future.wait([a, b, c]);
    expect(opens, 1);

    await HiveDeferredUserBoxes.ensureOpen(box);
    expect(opens, 1, reason: 'an open box is never re-opened');
  });

  test('records the deferred open with its duration and entry count',
      () async {
    final seeded = await Hive.openBox<dynamic>(box);
    await seeded.putAll({'a': 1, 'b': 2});
    await seeded.close();
    HiveOpenTiming.reset();

    HiveDeferredUserBoxes.arm(null);
    await HiveDeferredUserBoxes.ensureOpen(box);

    final record = HiveOpenTiming.opens.single;
    expect(record.name, box);
    expect(record.phase, HiveOpenTiming.deferredPhase);
    expect(record.entries, 2);
    expect(HiveOpenTiming.slowest, isNull,
        reason: 'a deferred open must not be reported as the first-frame '
            'long pole');
    expect(HiveOpenTiming.openedBoxes, isEmpty);
  });

  group('corruption', () {
    late File file;

    setUp(() {
      file = File('${dir.path}/$box.hive');
    });

    test('the frame encoder is faithful — a well-formed frame opens', () async {
      file.writeAsBytesSync(_frame('k', _stringValue('v')));
      final opened = await Hive.openBox<dynamic>(box);
      expect(opened.get('k'), 'v');
    });

    test('a box damaged beyond crash recovery surfaces as a '
        'HiveCorruptionException, is logged, and its file is NOT deleted',
        () async {
      // Valid checksum, unsupported key type: recovery cannot absorb it.
      final bytes = _frame('k', _stringValue('v'));
      bytes[4] = 7;
      final crcless = bytes.sublist(0, bytes.length - 4);
      final crc = ByteData(4)..setUint32(0, _crc32(crcless), Endian.little);
      final corrupt = Uint8List.fromList([...crcless, ...crc.buffer.asUint8List()]);
      file.writeAsBytesSync(corrupt);

      HiveDeferredUserBoxes.arm(null);
      await expectLater(HiveDeferredUserBoxes.ensureOpen(box),
          throwsA(isA<HiveCorruptionException>()));

      expect(file.existsSync(), isTrue);
      expect(file.readAsBytesSync(), corrupt,
          reason: 'user data is never silently deleted or truncated');
      expect(HiveDeferredUserBoxes.isReadable(box), isFalse);
      await pumpEventQueue();
      expect(recorder.captured, hasLength(1));
      expect(recorder.captured.single.layer, ErrorLayer.storage);
      expect(recorder.captured.single.inner, isA<HiveCorruptionException>());
    });

    test('the failure is remembered: no second open, no second log, and the '
        'waiting gates complete normally', () async {
      HiveDeferredUserBoxes.arm(null);
      var opens = 0;
      HiveDeferredUserBoxes.opener = (name, c) async {
        opens++;
        throw HiveError('Cannot read, unknown typeId: 200.');
      };

      await expectLater(HiveDeferredUserBoxes.ensureOpen(box),
          throwsA(isA<HiveCorruptionException>()));
      await expectLater(HiveDeferredUserBoxes.ensureOpen(box),
          throwsA(isA<HiveCorruptionException>()));
      await expectLater(HiveDeferredUserBoxes.settled(box), completes);

      var ran = false;
      await HiveDeferredUserBoxes.whenReadable(box, () async => ran = true);
      expect(ran, isFalse, reason: 'housekeeping skips a box that failed');
      expect(opens, 1);
      await pumpEventQueue();
      expect(recorder.captured, hasLength(1));
    });
  });
}
