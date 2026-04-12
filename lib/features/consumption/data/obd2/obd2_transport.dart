/// Abstract transport layer for OBD-II communication.
///
/// Implementations handle the actual I/O (Bluetooth, TCP, serial).
/// The [Elm327Protocol] builds commands and parses responses;
/// transport just moves bytes.
abstract class Obd2Transport {
  /// Connect to the OBD-II adapter.
  Future<void> connect();

  /// Send a command and wait for the response (terminated by '>').
  Future<String> sendCommand(String command);

  /// Disconnect from the adapter.
  Future<void> disconnect();

  /// Whether currently connected.
  bool get isConnected;
}

/// A fake transport for testing that returns pre-configured responses.
class FakeObd2Transport implements Obd2Transport {
  final Map<String, String> _responses;
  bool _connected = false;

  FakeObd2Transport([Map<String, String>? responses])
      : _responses = responses ?? {};

  @override
  Future<void> connect() async => _connected = true;

  @override
  Future<String> sendCommand(String command) async {
    if (!_connected) throw StateError('Not connected');
    final cmd = command.trim();
    return _responses[cmd] ?? 'NO DATA>';
  }

  @override
  Future<void> disconnect() async => _connected = false;

  @override
  bool get isConnected => _connected;
}
