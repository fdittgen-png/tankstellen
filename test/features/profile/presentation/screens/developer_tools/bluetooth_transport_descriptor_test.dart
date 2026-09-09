// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/api.dart';
import 'package:tankstellen/features/profile/presentation/screens/developer_tools/bluetooth_transport_descriptor.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #3984 — adding a [BluetoothTransport] value must be ONE edit.
///
/// The compiler enforces half of that: `descriptorFor`'s switch is
/// exhaustive, so a new value fails to compile there. This test enforces
/// the other half — that the new arm was actually filled in, rather than
/// wired to a placeholder that renders an empty tag.
void main() {
  late AppLocalizations l;

  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('en'));
  });

  test('every transport — null included — has a complete descriptor', () {
    final transports = <BluetoothTransport?>[null, ...BluetoothTransport.values];
    for (final transport in transports) {
      final d = descriptorFor(transport);
      expect(d.label(l), isNotEmpty, reason: 'no label for \$transport');
      expect(d.icon, isNotNull, reason: 'no icon for \$transport');
    }
  });

  test('the classified transports map onto a trace transport; the '
      'unclassified one deliberately does not', () {
    // A trace that claims a transport it could not determine is worse
    // than one that admits it does not know (#2969).
    expect(
      descriptorFor(BluetoothTransport.classic).connectTransport,
      Obd2ConnectTransport.classic,
    );
    expect(
      descriptorFor(BluetoothTransport.ble).connectTransport,
      Obd2ConnectTransport.ble,
    );
    expect(descriptorFor(null).connectTransport, isNull);
  });

  test('each transport reads differently — the tags are distinguishable', () {
    final labels = <BluetoothTransport?>[null, ...BluetoothTransport.values]
        .map((t) => descriptorFor(t).label(l))
        .toList();
    expect(labels.toSet(), hasLength(labels.length));
  });
}
