import 'dart:async';

import 'package:flutter/foundation.dart';

import 'classic_method_channel.dart';
import 'elm_byte_channel.dart';
import 'event_channel_cancel.dart';

/// Standard Bluetooth Serial Port Profile UUID (#761). Every
/// Classic-SPP ELM327 adapter (vLinker FS, OBDLink LX, generic
/// Amazon dongles) uses this same Bluetooth-SIG assigned base.
const String sppServiceUuid = '00001101-0000-1000-8000-00805f9b34fb';

/// [ElmByteChannel] backed by the in-repo MethodChannel plugin
/// [Obd2ClassicMethodChannel] (#763).
///
/// The plugin owns the native [android.bluetooth.BluetoothSocket];
/// this Dart class just relays the two directions — `write` goes
/// down via MethodChannel, `incoming` comes up via EventChannel.
/// The existing [BluetoothObd2Transport] sits on top and handles
/// the ELM327 `>`-prompt framing.
class ClassicElmChannel implements ElmByteChannel {
  final String address;
  final String sppUuid;
  final Obd2ClassicMethodChannel _plugin;

  StreamSubscription<List<int>>? _subscription;
  final StreamController<List<int>> _incoming =
      StreamController<List<int>>.broadcast();
  bool _open = false;

  ClassicElmChannel({
    required this.address,
    Obd2ClassicMethodChannel? plugin,
    this.sppUuid = sppServiceUuid,
  }) : _plugin = plugin ?? const Obd2ClassicMethodChannel();

  @override
  bool get isOpen => _open;

  @override
  Stream<List<int>> get incoming => _incoming.stream;

  @override
  Future<void> open() async {
    if (_open) return;
    final ok = await _plugin.connect(address: address, uuid: sppUuid);
    if (!ok) {
      throw StateError(
        'ClassicElmChannel: failed to open RFCOMM socket to $address '
        '(plugin returned false). Adapter may not be bonded or is out '
        'of range.',
      );
    }
    _subscription = _plugin.incoming.listen(
      _incoming.add,
      onError: (Object e, StackTrace st) {
        debugPrint('ClassicElmChannel: incoming error: $e');
      },
      onDone: () {
        _open = false;
      },
    );
    _open = true;
  }

  @override
  Future<void> write(List<int> bytes) async {
    if (!_open) {
      throw StateError('ClassicElmChannel: not open');
    }
    await _plugin.write(bytes);
  }

  @override
  Future<void> close() async {
    _open = false;
    await _subscription?.safeCancel();
    _subscription = null;
    try {
      await _plugin.disconnect();
    } catch (e, st) {
      debugPrint('ClassicElmChannel: disconnect error (ignored): $e\n$st');
    }
    await _incoming.close();
  }
}
