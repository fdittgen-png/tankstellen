// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapters/smart_obd_adapter.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapters/v_linker_fs_adapter.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm327_adapter.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm327_commands.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';

/// Transport that records every [sendCommand] invocation along with
/// the wall-clock timestamp at which the call was received. Used to
/// verify that the adapter-driven init loop preserves the legacy
/// hardcoded behaviour byte-for-byte (#1330 phase 1).
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
  group('GenericElm327Adapter (#1330 phase 1)', () {
    test('id is "generic"', () {
      const adapter = GenericElm327Adapter();
      expect(adapter.id, 'generic');
    });

    test('initSequence equals Elm327Commands.initCommands byte-for-byte', () {
      const adapter = GenericElm327Adapter();
      // Phase 1 contract: the generic adapter MUST mirror the legacy
      // global init list exactly, otherwise the refactor changes
      // observed behaviour.
      expect(adapter.initSequence, Elm327Commands.initCommands);
      // Spot-check the literal commands so a future edit to
      // [Elm327Commands.initCommands] surfaces here too.
      expect(adapter.initSequence, [
        'ATZ\r',
        'ATE0\r',
        'ATL0\r',
        'ATH0\r',
        'ATSP0\r',
        'ATAT1\r', // #1904 — adaptive timing (ATAT1, #1918)
      ]);
    });

    test('postResetDelay and interCommandDelay are both 100 ms', () {
      const adapter = GenericElm327Adapter();
      expect(adapter.postResetDelay, const Duration(milliseconds: 100));
      expect(adapter.interCommandDelay, const Duration(milliseconds: 100));
    });

    test('extraInitCommands is empty', () {
      const adapter = GenericElm327Adapter();
      expect(adapter.extraInitCommands, isEmpty);
    });

    test('preParse is the identity function', () {
      const adapter = GenericElm327Adapter();
      expect(adapter.preParse('foo'), 'foo');
      expect(adapter.preParse(''), '');
      expect(
        adapter.preParse('41 0C 0F A0>'),
        '41 0C 0F A0>',
      );
    });

    test('wakePolicy is the strict no-op default (#2268 concern 1)', () {
      const adapter = GenericElm327Adapter();
      final policy = adapter.wakePolicy;
      expect(policy.maySleep, isFalse,
          reason: 'a generic clone must not trigger any wake compensation');
      expect(policy.wakeSettle, Duration.zero);
      expect(policy.maxNudges, 0);
      expect(policy.isActive, isFalse,
          reason: 'a no-op policy must report itself inert so the connect '
              'path short-circuits before any extra settle');
    });
  });

  group('WakePolicy value object (#2268 concern 1)', () {
    test('default constructor is a strict no-op', () {
      const policy = WakePolicy();
      expect(policy.maySleep, isFalse);
      expect(policy.wakeSettle, Duration.zero);
      expect(policy.maxNudges, 0);
      expect(policy.isActive, isFalse);
    });

    test('named noop() constructor matches the default no-op', () {
      const policy = WakePolicy.noop();
      expect(policy.maySleep, isFalse);
      expect(policy.wakeSettle, Duration.zero);
      expect(policy.maxNudges, 0);
      expect(policy.isActive, isFalse);
    });

    test('isActive is true only when maySleep AND a window/nudge is granted',
        () {
      // maySleep alone with a zero window + zero nudges stays inert.
      expect(
        const WakePolicy(maySleep: true).isActive,
        isFalse,
        reason: 'maySleep with no settle and no nudge is still a no-op',
      );
      // A settle window with maySleep activates it.
      expect(
        const WakePolicy(
          maySleep: true,
          wakeSettle: Duration(milliseconds: 600),
        ).isActive,
        isTrue,
      );
      // A nudge alone with maySleep activates it.
      expect(
        const WakePolicy(maySleep: true, maxNudges: 1).isActive,
        isTrue,
      );
      // A settle window WITHOUT maySleep is inert — maySleep is the gate.
      expect(
        const WakePolicy(wakeSettle: Duration(seconds: 1), maxNudges: 1)
            .isActive,
        isFalse,
        reason: 'maySleep:false must override any seeded window/nudge',
      );
    });
  });

  group('Subclass wakePolicy defaults stay no-op (#2268 concern 1)', () {
    test('VLinkerFsAdapter is no-op', () {
      expect(const VLinkerFsAdapter().wakePolicy.isActive, isFalse);
    });

    test('SmartObdAdapter is no-op', () {
      expect(const SmartObdAdapter().wakePolicy.isActive, isFalse);
    });
  });

  group('Obd2Service.connect with default GenericElm327Adapter (#1330)', () {
    test(
      'sends the legacy init sequence in order, settling only after ATZ '
      '(#2261 concern 5 trimmed the inter-command sleeps)',
      () async {
        final transport = _RecordingObd2Transport({
          'ATZ': 'ELM327 v1.5>',
          'ATE0': 'OK>',
          'ATL0': 'OK>',
          'ATH0': 'OK>',
          'ATSP0': 'OK>',
          'ATAT1': 'OK>',
        });
        final service = Obd2Service(transport);

        final connected = await service.connect();

        expect(connected, isTrue);
        // Captured commands match the init list (#1904 added ATAT1),
        // followed by the #1401 phase 1 firmware-version probe.
        final sent = transport.commands.map((c) => c.command).toList();
        expect(sent, [
          'ATZ',
          'ATE0',
          'ATL0',
          'ATH0',
          'ATSP0',
          'ATAT1',
          'ATI',
        ]);

        // #2261 concern 5 — the ONLY settle is the postResetDelay after
        // ATZ (so ATE0, the command at index 1, follows a ~100 ms gap).
        // Every later command is serialised by the transport prompt-wait
        // with no extra blind sleep, so those gaps are near-zero.
        final gapAfterReset =
            transport.commands[1].at - transport.commands[0].at;
        expect(gapAfterReset,
            greaterThanOrEqualTo(const Duration(milliseconds: 90)),
            reason: 'a settle must follow ATZ');
        for (var i = 2; i < transport.commands.length; i++) {
          final gap = transport.commands[i].at - transport.commands[i - 1].at;
          expect(
            gap,
            lessThan(const Duration(milliseconds: 90)),
            reason: 'no fixed inter-command sleep before trivial AT echo '
                '$i (${transport.commands[i].command})',
          );
        }
      },
    );

    test('the active adapter is exposed as GenericElm327Adapter', () async {
      final transport = _RecordingObd2Transport({
        'ATZ': 'ELM327 v1.5>',
        'ATE0': 'OK>',
        'ATL0': 'OK>',
        'ATH0': 'OK>',
        'ATSP0': 'OK>',
      });
      final service = Obd2Service(transport);
      await service.connect();
      expect(service.adapter, isA<GenericElm327Adapter>());
      expect(service.adapter.id, 'generic');
    });
  });
}
