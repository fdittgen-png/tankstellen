import 'dart:async';

import 'elm_byte_channel.dart';

/// Standard Bluetooth Serial Port Profile UUID (#761). Every
/// Classic-SPP ELM327 adapter (vLinker FS, OBDLink LX, generic
/// Amazon dongles) uses this same Bluetooth-SIG assigned base.
const String sppServiceUuid = '00001101-0000-1000-8000-00805f9b34fb';

/// Placeholder [ElmByteChannel] for the Bluetooth-Classic SPP path
/// (#761).
///
/// The intended production impl wraps an RFCOMM socket opened via a
/// platform plugin. The popular \`flutter_blue_classic\` package is
/// GPL-3 licensed and incompatible with this MIT project (license
/// audit would fail CI). A follow-up issue tracks the license-clean
/// replacement — either a native MethodChannel wrapper in
/// \`android/app/src/main/kotlin/\` or an MIT-licensed Classic BT
/// plugin.
///
/// Until then, [open] throws so a user picking the Classic-only
/// path gets a typed \`Obd2AdapterUnresponsive\` back from the
/// connection service rather than a silent no-op. Tests inject a
/// fake [ElmByteChannel] instead of this class, so nothing breaks.
class ClassicElmChannel implements ElmByteChannel {
  final String _address;
  final String _sppUuid;

  ClassicElmChannel({
    required String address,
    String sppUuid = sppServiceUuid,
  })  : _address = address,
        _sppUuid = sppUuid;

  @override
  bool get isOpen => false;

  @override
  Stream<List<int>> get incoming => const Stream.empty();

  @override
  Future<void> open() async {
    throw StateError(
      'ClassicElmChannel: Bluetooth Classic SPP transport is not yet '
      'wired on this build (target $_address via $_sppUuid). Follow '
      '#761 for the license-clean native implementation. BLE '
      'adapters (vLinker FD / MC, OBDLink MX+, Carista, Veepeak) '
      'work today.',
    );
  }

  @override
  Future<void> write(List<int> bytes) async {
    throw StateError('ClassicElmChannel: not open');
  }

  @override
  Future<void> close() async {
    // no-op — nothing was opened.
  }
}
