import 'package:xml/xml.dart';

import 'obd2_debug_session.dart';

/// Serialises an [Obd2DebugSession] to a self-contained XML document
/// (#1925) — the format the opt-in OBD2 debug mode exports for
/// developer analysis of a failed connection / recording.
///
/// The BLE MAC is redacted to its last four characters (a full MAC is
/// a stable hardware identifier); no VIN or GPS data is ever held in a
/// session, so nothing else needs scrubbing.
///
/// Shape:
///
/// ```xml
/// <?xml version="1.0" encoding="UTF-8"?>
/// <Obd2DebugSession schema="1">
///   <Adapter mac="··············F:31"/>
///   <StartedAt>2026-05-18T14:27:07.000Z</StartedAt>
///   <EndedAt>2026-05-18T14:50:17.000Z</EndedAt>
///   <Summary durationSec="1390" handshakeCommands="6" .../>
///   <Events>
///     <Event t="..." kind="handshakeCommand" command="ATZ" .../>
///     <Event t="..." kind="dataGap" gapMs="9500"/>
///   </Events>
/// </Obd2DebugSession>
/// ```
String formatObd2DebugSessionXml(Obd2DebugSession session) {
  final builder = XmlBuilder();
  builder.processing('xml', 'version="1.0" encoding="UTF-8"');
  builder.element('Obd2DebugSession', nest: () {
    builder.attribute('schema', '1');

    builder.element('Adapter', nest: () {
      final name = session.adapterName;
      if (name != null && name.isNotEmpty) {
        builder.attribute('name', name);
      }
      final mac = session.adapterMac;
      if (mac != null && mac.isNotEmpty) {
        builder.attribute('mac', _redactMac(mac));
      }
    });

    builder.element('StartedAt',
        nest: session.startedAt.toIso8601String());
    final endedAt = session.endedAt;
    if (endedAt != null) {
      builder.element('EndedAt', nest: endedAt.toIso8601String());
    }

    final s = session.summary;
    builder.element('Summary', nest: () {
      final duration = s.duration;
      if (duration != null) {
        builder.attribute('durationSec', '${duration.inSeconds}');
      }
      builder.attribute('handshakeCommands', '${s.handshakeCommands}');
      builder.attribute('handshakeLatencyMs', '${s.handshakeLatencyMs}');
      builder.attribute('reconnectAttempts', '${s.reconnectAttempts}');
      builder.attribute('reconnectsSucceeded', '${s.reconnectsSucceeded}');
      builder.attribute('dataGaps', '${s.dataGaps}');
      builder.attribute('longestDataGapMs', '${s.longestDataGapMs}');
      builder.attribute('outcome', s.outcome);
    });

    builder.element('Events', nest: () {
      for (final e in session.events) {
        builder.element('Event', nest: () {
          builder.attribute('t', e.timestamp.toIso8601String());
          builder.attribute('kind', e.kind.name);
          final command = e.command;
          if (command != null) builder.attribute('command', command);
          final response = e.response;
          if (response != null) builder.attribute('response', response);
          final latencyMs = e.latencyMs;
          if (latencyMs != null) {
            builder.attribute('latencyMs', '$latencyMs');
          }
          final gapMs = e.gapMs;
          if (gapMs != null) builder.attribute('gapMs', '$gapMs');
          // Vehicle state around a data gap (#1930) — non-zero pre-gap
          // speed/rpm means the car was driving when data stopped (the
          // link died); zero means the engine was idle/off.
          final preSpeed = e.preGapSpeedKmh;
          if (preSpeed != null) {
            builder.attribute('preGapSpeedKmh', _num(preSpeed));
          }
          final preRpm = e.preGapRpm;
          if (preRpm != null) builder.attribute('preGapRpm', _num(preRpm));
          final postSpeed = e.postGapSpeedKmh;
          if (postSpeed != null) {
            builder.attribute('postGapSpeedKmh', _num(postSpeed));
          }
          final postRpm = e.postGapRpm;
          if (postRpm != null) builder.attribute('postGapRpm', _num(postRpm));
          final detail = e.detail;
          if (detail != null) builder.attribute('detail', detail);
        });
      }
    });
  });
  return builder.buildDocument().toXmlString(pretty: true);
}

/// Format a double for an XML attribute — drops a redundant `.0` so
/// `95.0` serialises as `95`, keeping the export readable.
String _num(double v) =>
    v == v.roundToDouble() ? '${v.toInt()}' : v.toString();

/// Redact a BLE MAC to its last four characters — a full MAC is a
/// stable hardware identifier (PII). Everything before the final four
/// characters becomes the middle-dot `·` so the length stays visible.
/// A string of four characters or fewer is returned unchanged.
String _redactMac(String mac) {
  if (mac.length <= 4) return mac;
  final visible = mac.substring(mac.length - 4);
  return '${'·' * (mac.length - 4)}$visible';
}
