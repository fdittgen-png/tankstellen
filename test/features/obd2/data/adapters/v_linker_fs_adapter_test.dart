// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/adapters/v_linker_fs_adapter.dart';
import 'package:tankstellen/features/obd2/data/elm327_commands.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_transport.dart';

/// Same Stopwatch-based recording transport pattern Phase 1's
/// regression test uses (`elm327_adapter_test.dart`). Records every
/// [sendCommand] call along with the elapsed wall-clock time so we can
/// assert the adapter's per-command delays are honoured.
class _RecordingObd2Transport implements Obd2Transport {
  final Map<String, String> _responses;
  final List<_RecordedCommand> commands = <_RecordedCommand>[];
  final Stopwatch _clock = Stopwatch();
  bool _connected = false;

  _RecordingObd2Transport([Map<String, String>? responses])
      : _responses = responses ?? const {};

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async {
    _connected = true;
    _clock.start();
  }

  @override
  Future<String> sendCommand(String command) async {
    if (!_connected) throw StateError('Not connected');
    commands.add(_RecordedCommand(command.trim(), _clock.elapsed));
    return _responses[command.trim()] ?? 'NO DATA>';
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    _clock.stop();
  }
}

class _RecordedCommand {
  final String command;
  final Duration at;
  const _RecordedCommand(this.command, this.at);
}

void main() {
  group('VLinkerFsAdapter (#1330 phase 2)', () {
    test('id is "vlinker-fs"', () {
      const adapter = VLinkerFsAdapter();
      expect(adapter.id, 'vlinker-fs');
    });

    test('initSequence equals Elm327Commands.initCommands byte-for-byte', () {
      const adapter = VLinkerFsAdapter();
      // vLinker FS uses the standard ELM327 init list — only the
      // delays differ from the generic profile.
      expect(adapter.initSequence, Elm327Commands.initCommands);
      expect(adapter.initSequence, [
        'ATZ\r',
        'ATE0\r',
        'ATL0\r',
        'ATH0\r',
        'ATSP0\r',
        'ATAT1\r', // #1904 — adaptive timing (ATAT1, #1918)
      ]);
    });

    test('postResetDelay is 1 s (#2969 cold-clone settle)', () {
      const adapter = VLinkerFsAdapter();
      // #2969 — bumped 200 ms → 1 s: field evidence the real vLinker FS-class
      // hardware (and the cheaper clones using its name) needs ≥1 s to
      // re-enumerate after ATZ before answering the next command.
      expect(adapter.postResetDelay, const Duration(seconds: 1));
    });

    test('interCommandDelay is 50 ms', () {
      const adapter = VLinkerFsAdapter();
      expect(adapter.interCommandDelay, const Duration(milliseconds: 50));
    });

    test('extraInitCommands is empty', () {
      const adapter = VLinkerFsAdapter();
      expect(adapter.extraInitCommands, isEmpty);
    });

    test('preParse is the identity function', () {
      const adapter = VLinkerFsAdapter();
      expect(adapter.preParse(''), '');
      expect(adapter.preParse('foo'), 'foo');
      expect(adapter.preParse('41 0C 0F A0>'), '41 0C 0F A0>');
    });
  });

  group('Obd2Service.connect with VLinkerFsAdapter (#1330 phase 2)', () {
    test(
      'settles postResetDelay after ATZ only — no inter-command sleep between '
      'trivial AT echoes (#2261 concern 5, #2969)',
      () async {
        final transport = _RecordingObd2Transport({
          'ATZ': 'ELM327 v1.5>',
          'ATE0': 'OK>',
          'ATL0': 'OK>',
          'ATH0': 'OK>',
          'ATSP0': 'OK>',
        });
        final service = Obd2Service(transport);

        final connected =
            await service.connect(adapter: const VLinkerFsAdapter());

        expect(connected, isTrue);
        expect(service.adapter, isA<VLinkerFsAdapter>());

        final sent = transport.commands.map((c) => c.command).toList();
        // #1401 phase 1: the connect path now appends an `ATI`
        // firmware-version probe after the init sequence. Subject to
        // the same interCommandDelay as the rest of the loop.
        expect(sent, ['ATZ', 'ATE0', 'ATL0', 'ATH0', 'ATSP0', 'ATAT1', 'ATI']);

        // Gap between cmd[0] (ATZ) and cmd[1] (ATE0) reflects the
        // 200 ms postResetDelay. Generous lower bound (180 ms) avoids
        // flakiness on slow CI; the assertion that matters is "we DID
        // wait at least the configured 200 ms".
        final firstGap = transport.commands[1].at - transport.commands[0].at;
        expect(
          firstGap,
          greaterThanOrEqualTo(const Duration(milliseconds: 180)),
          reason: 'postResetDelay (gap before ATE0)',
        );

        // #2261 concern 5 — the interCommandDelay is no longer paid
        // between trivial AT echoes (the transport prompt-wait already
        // serialises them), so subsequent gaps are near-zero.
        for (var i = 2; i < transport.commands.length; i++) {
          final gap = transport.commands[i].at - transport.commands[i - 1].at;
          expect(
            gap,
            lessThan(const Duration(milliseconds: 40)),
            reason: 'no fixed inter-command sleep before command $i = '
                '${transport.commands[i].command}',
          );
        }
      },
    );
  });
}
