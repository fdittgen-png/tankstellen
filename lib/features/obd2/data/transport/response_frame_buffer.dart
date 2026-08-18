// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Outcome of feeding one raw byte chunk into a [ResponseFrameBuffer].
enum FrameOutcome {
  /// No `>` prompt yet — keep accumulating.
  needMore,

  /// A complete `>`-terminated frame is ready in [ResponseFrameBuffer.body].
  complete,

  /// The accumulation exceeded the cap without a prompt (#3276) — a
  /// never-prompting / runaway adapter. The buffer was cleared; the caller
  /// should fail the in-flight command fast rather than grow unbounded.
  overflow,
}

/// Accumulates ELM327 response bytes until the `>` prompt (0x3E), with a hard
/// size cap (#3276).
///
/// Every ELM327 reply ends with `>`; BLE notifications commonly arrive as
/// 20-byte chunks, so the transport accumulates until the prompt is seen, then
/// hands back everything before it. A clone that streams without ever emitting
/// the prompt (or a garbage frame) would otherwise grow the buffer unbounded
/// within the generous (up to ~15 s) read window — so once accumulation
/// crosses [maxChars] (8 KB, far above any legitimate frame including a
/// multi-frame VIN / supported-PID dump) the buffer is dropped and [FrameOutcome.overflow]
/// is returned. Pulled out of the transport so the framing + clamp are unit-
/// testable in isolation and the transport file stays under the line cap.
class ResponseFrameBuffer {
  ResponseFrameBuffer({this.maxChars = 8192});

  /// Hard ceiling on the accumulation before [add] returns [FrameOutcome.overflow].
  final int maxChars;

  final StringBuffer _buf = StringBuffer();
  String? _body;

  /// The body of the most recently completed frame (everything before the
  /// `>`), valid after [add] returns [FrameOutcome.complete].
  String? get body => _body;

  /// Discard any partially-accumulated bytes (e.g. before a fresh command or
  /// on disconnect).
  void clear() => _buf.clear();

  /// Feed one raw incoming [chunk]. Returns whether a frame completed, more
  /// bytes are needed, or the cap was exceeded.
  FrameOutcome add(List<int> chunk) {
    _buf.write(String.fromCharCodes(chunk));
    if (_buf.length > maxChars) {
      _buf.clear();
      return FrameOutcome.overflow;
    }
    final content = _buf.toString();
    final promptIdx = content.indexOf('>');
    if (promptIdx < 0) return FrameOutcome.needMore;
    _body = content.substring(0, promptIdx);
    _buf.clear();
    // Keep any bytes past the prompt (rare but legal) for the next frame.
    if (promptIdx + 1 < content.length) {
      _buf.write(content.substring(promptIdx + 1));
    }
    return FrameOutcome.complete;
  }
}
