import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapters/smart_obd_adapter.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm327_commands.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';

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
  group('SmartObdAdapter (#1330 phase 2)', () {
    test('id is "smart-obd"', () {
      const adapter = SmartObdAdapter();
      expect(adapter.id, 'smart-obd');
    });

    test('initSequence equals Elm327Commands.initCommands byte-for-byte', () {
      const adapter = SmartObdAdapter();
      expect(adapter.initSequence, Elm327Commands.initCommands);
      expect(adapter.initSequence, [
        'ATZ\r',
        'ATE0\r',
        'ATL0\r',
        'ATH0\r',
        'ATSP0\r',
      ]);
    });

    test('postResetDelay is 400 ms', () {
      const adapter = SmartObdAdapter();
      expect(adapter.postResetDelay, const Duration(milliseconds: 400));
    });

    test('interCommandDelay is 200 ms', () {
      const adapter = SmartObdAdapter();
      expect(adapter.interCommandDelay, const Duration(milliseconds: 200));
    });

    test('extraInitCommands is empty', () {
      const adapter = SmartObdAdapter();
      expect(adapter.extraInitCommands, isEmpty);
    });

    group('preParse', () {
      test('returns identity for the empty string', () {
        const adapter = SmartObdAdapter();
        expect(adapter.preParse(''), '');
      });

      test('preserves a clean response with only the terminating prompt', () {
        const adapter = SmartObdAdapter();
        // No stray `>` characters in the body — output must equal input.
        expect(adapter.preParse('41 0D 32\r\r>'), '41 0D 32\r\r>');
        expect(adapter.preParse('OK>'), 'OK>');
      });

      test('strips stray mid-frame `>` but preserves the final terminator',
          () {
        const adapter = SmartObdAdapter();
        // Documented quirk: SmartOBD firmware sometimes emits stray
        // `>` prompts mid-frame. preParse strips them everywhere
        // except the final terminator (which downstream
        // Elm327Parsers.cleanResponse expects to remove itself).
        expect(
          adapter.preParse('OK>extra>41 0D 32>'),
          'OKextra41 0D 32>',
        );
      });

      test('handles a single trailing `>` with no stray prompts', () {
        const adapter = SmartObdAdapter();
        expect(
          adapter.preParse('41 0C 0F A0>'),
          '41 0C 0F A0>',
        );
      });

      test('strips multiple stray `>` characters before the terminator', () {
        const adapter = SmartObdAdapter();
        expect(
          adapter.preParse('>>>OK>'),
          'OK>',
        );
      });

      test('does not corrupt valid PID payloads with embedded carriage returns',
          () {
        const adapter = SmartObdAdapter();
        // The CR/LF separators that ELM327 emits between frames must
        // pass through untouched — only `>` is the target.
        const raw = '41 0D 32\r\r41 0C 0F A0\r\r>';
        expect(adapter.preParse(raw), raw);
      });

      test('returns input unchanged when there is no `>` at all', () {
        const adapter = SmartObdAdapter();
        expect(adapter.preParse('41 0D 32'), '41 0D 32');
      });
    });
  });

  group('Obd2Service.connect with SmartObdAdapter (#1330 phase 2)', () {
    test(
      'waits 400 ms after ATZ and 200 ms between subsequent init commands',
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
            await service.connect(adapter: const SmartObdAdapter());

        expect(connected, isTrue);
        expect(service.adapter, isA<SmartObdAdapter>());

        final sent = transport.commands.map((c) => c.command).toList();
        expect(sent, ['ATZ', 'ATE0', 'ATL0', 'ATH0', 'ATSP0']);

        // Gap before ATE0 reflects the 400 ms postResetDelay.
        final firstGap = transport.commands[1].at - transport.commands[0].at;
        expect(
          firstGap,
          greaterThanOrEqualTo(const Duration(milliseconds: 380)),
          reason: 'postResetDelay (gap before ATE0)',
        );

        // Subsequent gaps reflect the 200 ms interCommandDelay.
        for (var i = 2; i < transport.commands.length; i++) {
          final gap = transport.commands[i].at - transport.commands[i - 1].at;
          expect(
            gap,
            greaterThanOrEqualTo(const Duration(milliseconds: 180)),
            reason:
                'interCommandDelay (gap before command $i = ${transport.commands[i].command})',
          );
          expect(
            gap,
            lessThan(const Duration(milliseconds: 380)),
            reason:
                'gap before command $i should reflect 200 ms interCommandDelay, '
                'not the 400 ms postResetDelay',
          );
        }
      },
    );
  });
}
