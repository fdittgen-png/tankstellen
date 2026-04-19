/// Raw byte pipe to an ELM327-compatible adapter.
///
/// Abstracted so [BluetoothObd2Transport] can be unit-tested with a
/// fake channel — the real Bluetooth implementation lives in
/// [FlutterBluePlusElmChannel] (step 1 of #716).
abstract class ElmByteChannel {
  /// Open the channel — e.g. connect BLE, discover services, enable
  /// notifications. Throws on failure. Idempotent: opening an already
  /// open channel is a no-op.
  Future<void> open();

  /// Write raw [bytes] to the adapter. The ELM327 expects ASCII
  /// command strings terminated by `\r`.
  Future<void> write(List<int> bytes);

  /// Stream of bytes coming back from the adapter. Consumers
  /// accumulate until the ELM prompt character `>` (0x3E) arrives.
  Stream<List<int>> get incoming;

  /// Close the channel and release resources. Idempotent.
  Future<void> close();

  bool get isOpen;
}
