import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_debug_session.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_debug_session_xml.dart';
import 'package:xml/xml.dart';

/// Unit tests for `formatObd2DebugSessionXml` (#1925).
void main() {
  final t0 = DateTime.utc(2026, 5, 18, 14);
  DateTime at(int s) => t0.add(Duration(seconds: s));

  Obd2DebugSession buildSession() {
    final session = Obd2DebugSession(
      startedAt: t0,
      adapterName: 'SmartOBD',
      adapterMac: 'AA:BB:CC:DD:EE:FF',
    )..endedAt = at(90);
    session.events
      ..add(Obd2SessionEvent(
        timestamp: t0,
        kind: Obd2SessionEventKind.sessionStarted,
      ))
      ..add(Obd2SessionEvent(
        timestamp: at(1),
        kind: Obd2SessionEventKind.handshakeCommand,
        command: 'ATZ',
        response: 'ELM327 v1.5',
        latencyMs: 120,
      ))
      ..add(Obd2SessionEvent(
        timestamp: at(2),
        kind: Obd2SessionEventKind.connectionEstablished,
        detail: 'ELM327 v1.5',
      ))
      ..add(Obd2SessionEvent(
        timestamp: at(30),
        kind: Obd2SessionEventKind.dataGap,
        gapMs: 9500,
        preGapSpeedKmh: 95,
        preGapRpm: 2200,
        postGapSpeedKmh: 0,
        postGapRpm: 0,
      ))
      ..add(Obd2SessionEvent(
        timestamp: at(90),
        kind: Obd2SessionEventKind.sessionEnded,
      ));
    return session;
  }

  test('produces a well-formed XML document', () {
    final xml = formatObd2DebugSessionXml(buildSession());
    // Parsing throws on malformed XML — this is the assertion.
    final doc = XmlDocument.parse(xml);
    expect(doc.rootElement.name.local, 'Obd2DebugSession');
    expect(doc.rootElement.getAttribute('schema'), '1');
  });

  test('redacts the BLE MAC to its last four characters', () {
    final xml = formatObd2DebugSessionXml(buildSession());
    expect(xml, isNot(contains('AA:BB:CC:DD:EE:FF')));
    final mac = XmlDocument.parse(xml)
        .rootElement
        .getElement('Adapter')!
        .getAttribute('mac')!;
    expect(mac, endsWith('E:FF'));
    expect(mac, contains('·'));
  });

  test('serialises the summary attributes', () {
    final doc = formatObd2DebugSessionXml(buildSession());
    final summary =
        XmlDocument.parse(doc).rootElement.getElement('Summary')!;
    expect(summary.getAttribute('durationSec'), '90');
    expect(summary.getAttribute('handshakeCommands'), '1');
    expect(summary.getAttribute('handshakeLatencyMs'), '120');
    expect(summary.getAttribute('dataGaps'), '1');
    expect(summary.getAttribute('longestDataGapMs'), '9500');
    expect(summary.getAttribute('outcome'), 'established');
  });

  test('serialises each event with its fields', () {
    final doc = XmlDocument.parse(formatObd2DebugSessionXml(buildSession()));
    final events =
        doc.rootElement.getElement('Events')!.findElements('Event').toList();
    expect(events, hasLength(5));

    final handshake = events.firstWhere(
        (e) => e.getAttribute('kind') == 'handshakeCommand');
    expect(handshake.getAttribute('command'), 'ATZ');
    expect(handshake.getAttribute('response'), 'ELM327 v1.5');
    expect(handshake.getAttribute('latencyMs'), '120');

    final gap =
        events.firstWhere((e) => e.getAttribute('kind') == 'dataGap');
    expect(gap.getAttribute('gapMs'), '9500');
  });

  test('a data gap serialises the pre/post-gap vehicle state (#1930)', () {
    final doc = XmlDocument.parse(formatObd2DebugSessionXml(buildSession()));
    final gap = doc.rootElement
        .getElement('Events')!
        .findElements('Event')
        .firstWhere((e) => e.getAttribute('kind') == 'dataGap');
    // Pre-gap moving, post-gap stopped — the link died mid-drive. A
    // whole .0 is dropped so the export reads cleanly.
    expect(gap.getAttribute('preGapSpeedKmh'), '95');
    expect(gap.getAttribute('preGapRpm'), '2200');
    expect(gap.getAttribute('postGapSpeedKmh'), '0');
    expect(gap.getAttribute('postGapRpm'), '0');
  });

  test('an in-progress session (no endedAt) still serialises', () {
    final session = Obd2DebugSession(startedAt: t0)
      ..events.add(Obd2SessionEvent(
        timestamp: t0,
        kind: Obd2SessionEventKind.sessionStarted,
      ));
    final doc = XmlDocument.parse(formatObd2DebugSessionXml(session));
    expect(doc.rootElement.getElement('EndedAt'), isNull);
    expect(doc.rootElement.getElement('Summary')!.getAttribute('outcome'),
        'unknown');
  });
}
