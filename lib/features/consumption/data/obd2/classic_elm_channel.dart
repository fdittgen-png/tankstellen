import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';

import 'elm_byte_channel.dart';

/// Standard Bluetooth Serial Port Profile UUID (#761). Every
/// Classic-SPP ELM327 adapter (vLinker FS, OBDLink LX, the Amazon
/// "OBDII" generics) uses this same UUID for their RFCOMM service;
/// it's the Bluetooth SIG-assigned base UUID for SPP.
const String sppServiceUuid = '00001101-0000-1000-8000-00805f9b34fb';

/// [ElmByteChannel] backed by a Bluetooth Classic RFCOMM socket
/// opened through `flutter_blue_classic` (#761).
///
/// Wraps a [BluetoothConnection]'s `input` stream (incoming bytes
/// from the adapter) and `output` sink (bytes we write). The outer
/// [BluetoothObd2Transport] does all the ELM327 protocol framing —
/// this channel is a dumb byte pipe.
class ClassicElmChannel implements ElmByteChannel {
  final FlutterBlueClassic _plugin;
  final String _address;
  final String _sppUuid;

  BluetoothConnection? _connection;
  StreamSubscription<List<int>>? _subscription;
  final StreamController<List<int>> _incoming =
      StreamController<List<int>>.broadcast();
  bool _open = false;

  ClassicElmChannel({
    required String address,
    FlutterBlueClassic? plugin,
    String sppUuid = sppServiceUuid,
  })  : _plugin = plugin ?? FlutterBlueClassic(),
        _address = address,
        _sppUuid = sppUuid;

  @override
  bool get isOpen => _open;

  @override
  Stream<List<int>> get incoming => _incoming.stream;

  @override
  Future<void> open() async {
    if (_open) return;
    final conn = await _plugin.connect(_address, uuid: _sppUuid);
    if (conn == null) {
      throw StateError(
        'ClassicElmChannel: failed to open RFCOMM socket to $_address '
        '(plugin returned null). Adapter may not be bonded or is out '
        'of range.',
      );
    }
    _connection = conn;
    final input = conn.input;
    if (input == null) {
      await conn.close();
      throw StateError(
        'ClassicElmChannel: socket opened but input stream is null',
      );
    }
    _subscription = input.listen(
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
    final conn = _connection;
    if (conn == null || !_open) {
      throw StateError('ClassicElmChannel: not open');
    }
    conn.output.add(Uint8List.fromList(bytes));
    await conn.output.allSent;
  }

  @override
  Future<void> close() async {
    _open = false;
    await _subscription?.cancel();
    _subscription = null;
    try {
      await _connection?.close();
    } catch (e) {
      debugPrint('ClassicElmChannel: close error (ignored): $e');
    }
    _connection = null;
    await _incoming.close();
  }
}
