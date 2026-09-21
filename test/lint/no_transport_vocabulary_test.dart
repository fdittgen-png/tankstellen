// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// #4141 — no transport, protocol, library or stack-trace vocabulary in
/// a string a user reads.
///
/// The shapes this exists to keep out, all of which have reached a
/// screen in this app's history:
///
///     RFCOMM connection failed · retry strategy exhausted
///     DioException [connection timeout] …
///     a storage box could not be opened (…)
///
/// Two things it deliberately does NOT forbid:
///
///  * **Words the user genuinely owns.** "API key" is a thing a user
///    registers for at Tankerkönig; "JSON" and "SQL" are export formats
///    they copy and paste. Naming those is not leaking an implementation
///    detail, it is naming the thing on their screen.
///  * **The developer-facing adapter test screen**, which exists to tell
///    someone which Bluetooth transport their ELM327 negotiated. Saying
///    "Classic (SPP)" there IS the feature.
///
/// The baseline below is therefore the exemption list, not a debt list,
/// and it may only shrink. A new hit is a defect, not a number to raise —
/// #4118 is the cautionary case: the copy told users their data was
/// damaged and to clear storage, for a fault that was neither.
void main() {
  /// Vocabulary that must never reach a user-facing value. Keyed by the
  /// name that appears in the failure message.
  const forbidden = <String, String>{
    'RFCOMM': r'\bRFCOMM\b',
    'Dio': r'\bDio(Exception)?\b',
    'socket': r'\bsockets?\b',
    'Hive': r'\bHive\b',
    'null': r'\bnull\b',
    'Exception': r'\bExceptions?\b',
    'stack frame': r'#\d+\s+\w+|\.dart:\d+',
    'HTTP status': r'\bHTTP \d{3}\b',
    'TCP/UDP': r'\b(TCP|UDP)\b',
    'GATT': r'\bGATT\b',
    'link layer': r'\b(BLE|SPP|ELM327|ATSP\d)\b',
    'stringified map': r'\{[a-zA-Z_]+: ',
  };

  /// Keys allowed to carry one of the above, each with the reason.
  /// Ratchet-DOWN only: removing an entry is the goal, adding one needs
  /// the reason to survive review.
  const exemptions = <String, String>{
    'obd2TestAdapterTransportClassic':
        'the OBD2 adapter test screen exists to report the negotiated '
            'Bluetooth transport; naming it IS the feature (#3346)',
    'obd2TestAdapterTransportUnknown':
        'same screen, the other branch — "defaulting to BLE" is the '
            'diagnostic the screen was built to show (#3346)',
  };

  late Map<String, Object?> arb;

  setUpAll(() {
    arb = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
        as Map<String, Object?>;
  });

  test('no user-facing English string names a transport, library or trace',
      () {
    final offenders = <String>[];
    for (final entry in arb.entries) {
      final key = entry.key;
      final value = entry.value;
      // `@key` entries are developer-facing metadata, and `@@locale` is
      // not a string a user reads.
      if (key.startsWith('@') || value is! String) continue;
      if (exemptions.containsKey(key)) continue;
      for (final vocab in forbidden.entries) {
        if (RegExp(vocab.value).hasMatch(value)) {
          offenders.add('$key — ${vocab.key} — "$value"');
        }
      }
    }

    expect(offenders, isEmpty,
        reason: 'A user-facing string names something only a developer '
            'cares about. #4141: what happened, why it matters, can I '
            'continue, what do I do — in the user\'s terms. The '
            'diagnostic belongs in RecoveryMessage.diagnostic, one tap '
            'deeper.\n\n${offenders.join('\n')}');
  });

  test('the exemption list has no stale entries', () {
    for (final key in exemptions.keys) {
      expect(arb.containsKey(key), isTrue,
          reason: '$key no longer exists — drop it from the exemption '
              'list rather than leaving a rule nobody enforces');
      final value = arb[key]! as String;
      final stillNeeded =
          forbidden.values.any((p) => RegExp(p).hasMatch(value));
      expect(stillNeeded, isTrue,
          reason: '$key no longer carries any forbidden vocabulary — '
              'remove its exemption. This ratchet only goes down.');
    }
  });
}
