// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:isolate';

import '../domain/services/recording_isolate_protocol.dart';

/// #3321 (Epic #3314) — hosts the recording loop in a dedicated background
/// isolate so it survives independently of the UI isolate (which Flutter
/// pauses when the app is backgrounded). The foreground service keeps the
/// process alive; this host keeps the recording WORK off the UI isolate.
///
/// FOUNDATION ONLY (non-destructive). The live recording cutover — running
/// the geolocator subscription + WAL writes inside the spawned isolate via
/// `BackgroundIsolateBinaryMessenger` — is the on-device-validation step
/// deferred until the #3173 FGS form clears (a geolocator-in-isolate path
/// can only be verified on hardware). Today's UI-isolate
/// [GpsOnlyRecordingPipeline] stays the untouched default; this host is gated
/// behind `kGpsRecordingForegroundServiceEnabled` at its (future) call site.
///
/// What IS done + tested here: the isolate lifecycle + the port handshake +
/// the typed [RecordingFixMessage] / [RecordingIsolateCommand] protocol, so
/// the cutover is a wiring step on a proven transport rather than new plumbing.
class RecordingIsolateHost {
  Isolate? _isolate;
  ReceivePort? _fromIsolate;
  SendPort? _toIsolate;
  final _fixes = StreamController<RecordingFixMessage>.broadcast();
  final _ready = Completer<void>();

  /// Decoded GPS fixes streamed back from the recording isolate.
  Stream<RecordingFixMessage> get fixes => _fixes.stream;

  /// Completes once the isolate has sent back its command [SendPort]
  /// (the handshake), i.e. it is ready to receive commands.
  Future<void> get ready => _ready.future;

  /// Spawn [entryPoint] in a new isolate, handing it the host's [SendPort].
  /// The entry point must send its own command [SendPort] back as the FIRST
  /// message (the handshake); subsequent messages are fix maps.
  Future<void> spawn(void Function(SendPort) entryPoint) async {
    final from = ReceivePort();
    _fromIsolate = from;
    from.listen(_onMessage);
    _isolate = await Isolate.spawn(entryPoint, from.sendPort);
  }

  void _onMessage(Object? message) {
    // First message is the handshake: the isolate's command SendPort.
    if (message is SendPort) {
      _toIsolate = message;
      if (!_ready.isCompleted) _ready.complete();
      return;
    }
    final fix = decodeRecordingFix(message);
    if (fix != null && !_fixes.isClosed) {
      _fixes.add(fix);
    }
  }

  /// Send a control command to the isolate. No-op until the handshake lands.
  void send(RecordingIsolateCommand command) {
    _toIsolate?.send(encodeRecordingCommand(command));
  }

  /// Tear down the isolate and the port (end of trip).
  Future<void> dispose() async {
    try {
      _toIsolate?.send(encodeRecordingCommand(RecordingIsolateCommand.stop));
    } catch (_) {
      // ignore: silent_catch — best-effort stop on a port that may already be
      // closed (the isolate could have exited); dispose must never throw
      // during teardown, and there is no actionable cause to log here.
    }
    _fromIsolate?.close();
    _fromIsolate = null;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _toIsolate = null;
    if (!_fixes.isClosed) await _fixes.close();
  }
}
