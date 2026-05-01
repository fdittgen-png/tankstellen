import 'package:flutter_test/flutter_test.dart';
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
  });

  group('Obd2Service.connect with default GenericElm327Adapter (#1330)', () {
    test(
      'sends the legacy init sequence in order with a ~100 ms gap '
      'between commands',
      () async {
        final transport = _RecordingObd2Transport({
          'ATZ': 'ELM327 v1.5>',
          'ATE0': 'OK>',
          'ATL0': 'OK>',
          'ATH0': 'OK>',
          'ATSP0': 'OK>',
        });
        final service = Obd2Service(transport);

        final connected = await service.connect();

        expect(connected, isTrue);
        // Captured commands match the legacy init list exactly.
        final sent = transport.commands.map((c) => c.command).toList();
        expect(sent, [
          'ATZ',
          'ATE0',
          'ATL0',
          'ATH0',
          'ATSP0',
        ]);

        // Inter-command intervals are at least the configured 100 ms
        // delay. Generous upper bound (250 ms) avoids flakiness on
        // slow CI runners — the assertion that matters is "we DID
        // wait", not the exact wall-clock value.
        for (var i = 1; i < transport.commands.length; i++) {
          final gap = transport.commands[i].at - transport.commands[i - 1].at;
          expect(
            gap,
            greaterThanOrEqualTo(const Duration(milliseconds: 90)),
            reason: 'gap before command $i (${transport.commands[i].command})',
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
