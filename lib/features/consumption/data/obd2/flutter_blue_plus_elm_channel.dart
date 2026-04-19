import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'elm_byte_channel.dart';

/// Standard SPP-over-BLE UUIDs exposed by Vgate vLinker and most
/// ELM327 BLE clones (Nordic UART Service variant used by the
/// adapter firmware). If the adapter in front of you doesn't match
/// these, pass your own via [ble327ServiceUuid] / [writeCharUuid] /
/// [notifyCharUuid].
class Elm327BleUuids {
  final Guid service;
  final Guid writeChar;
  final Guid notifyChar;

  const Elm327BleUuids({
    required this.service,
    required this.writeChar,
    required this.notifyChar,
  });

  /// Defaults observed on real vLinker FS / FD / MC adapters + most
  /// BLE ELM327 clones.
  static final vgate = Elm327BleUuids(
    service: Guid('0000fff0-0000-1000-8000-00805f9b34fb'),
    writeChar: Guid('0000fff2-0000-1000-8000-00805f9b34fb'),
    notifyChar: Guid('0000fff1-0000-1000-8000-00805f9b34fb'),
  );
}

/// [ElmByteChannel] backed by flutter_blue_plus. Connects to a single
/// [BluetoothDevice], discovers the ELM327 service, enables notifies
/// on the incoming characteristic, and exposes write + notify as the
/// abstract channel contract.
///
/// This class is Android-oriented (vLinker FS is BLE on Android).
/// It is untested on iOS — flutter_blue_plus is cross-platform but
/// iOS BLE ELM adapters are rare; add iOS-specific handling when the
/// app starts supporting them.
class FlutterBluePlusElmChannel implements ElmByteChannel {
  final BluetoothDevice _device;
  final Elm327BleUuids _uuids;
  BluetoothCharacteristic? _writeChar;
  BluetoothCharacteristic? _notifyChar;
  StreamSubscription<List<int>>? _subscription;
  final StreamController<List<int>> _incoming =
      StreamController<List<int>>.broadcast();
  bool _open = false;

  FlutterBluePlusElmChannel(
    this._device, {
    Elm327BleUuids? uuids,
  }) : _uuids = uuids ?? Elm327BleUuids.vgate;

  @override
  bool get isOpen => _open;

  @override
  Stream<List<int>> get incoming => _incoming.stream;

  @override
  Future<void> open() async {
    if (_open) return;
    await _device.connect(autoConnect: false, mtu: null);
    final services = await _device.discoverServices();
    final service = services.firstWhere(
      (s) => s.uuid == _uuids.service,
      orElse: () => throw StateError(
        'BLE device ${_device.remoteId.str} has no ELM327 service '
        '${_uuids.service}',
      ),
    );
    _writeChar = service.characteristics.firstWhere(
      (c) => c.uuid == _uuids.writeChar,
      orElse: () => throw StateError(
        'BLE device has no write characteristic ${_uuids.writeChar}',
      ),
    );
    _notifyChar = service.characteristics.firstWhere(
      (c) => c.uuid == _uuids.notifyChar,
      orElse: () => throw StateError(
        'BLE device has no notify characteristic ${_uuids.notifyChar}',
      ),
    );
    await _notifyChar!.setNotifyValue(true);
    _subscription = _notifyChar!.lastValueStream.listen(
      (bytes) => _incoming.add(bytes),
      onError: (e, st) {
        debugPrint('FlutterBluePlusElmChannel notify error: $e');
      },
    );
    _open = true;
  }

  @override
  Future<void> write(List<int> bytes) async {
    final char = _writeChar;
    if (char == null) {
      throw StateError('Channel not open — call open() first');
    }
    // withoutResponse lets the adapter write as fast as BLE allows;
    // the ELM327 replies via notify anyway.
    await char.write(bytes, withoutResponse: true);
  }

  @override
  Future<void> close() async {
    _open = false;
    await _subscription?.cancel();
    _subscription = null;
    try {
      await _device.disconnect();
    } catch (e) {
      debugPrint('FlutterBluePlusElmChannel: disconnect failed: $e');
    }
    _writeChar = null;
    _notifyChar = null;
  }
}
