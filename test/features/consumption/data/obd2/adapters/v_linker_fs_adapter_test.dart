import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapters/v_linker_fs_adapter.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm327_commands.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';

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
      ]);
    });

    test('postResetDelay is 200 ms', () {
      const adapter = VLinkerFsAdapter();
      expect(adapter.postResetDelay, const Duration(milliseconds: 200));
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
      'waits 200 ms after the first command and 50 ms between subsequent ones',
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
        expect(sent, ['ATZ', 'ATE0', 'ATL0', 'ATH0', 'ATSP0']);

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

        // Subsequent gaps reflect the 50 ms interCommandDelay.
        for (var i = 2; i < transport.commands.length; i++) {
          final gap = transport.commands[i].at - transport.commands[i - 1].at;
          expect(
            gap,
            greaterThanOrEqualTo(const Duration(milliseconds: 40)),
            reason:
                'interCommandDelay (gap before command $i = ${transport.commands[i].command})',
          );
          // Generous upper bound: real interCommandDelay should be
          // ~50ms, well below the 200ms postReset value. This guards
          // against accidentally swapping the two in the connect loop.
          expect(
            gap,
            lessThan(const Duration(milliseconds: 180)),
            reason:
                'gap before command $i should reflect 50 ms interCommandDelay, '
                'not the 200 ms postResetDelay',
          );
        }
      },
    );
  });
}
