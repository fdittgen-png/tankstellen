// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../obd2/api.dart';

/// What the self-test surfaces need to know about a
/// [BluetoothTransport] (#3984, epic #3952).
///
/// Before this, two files each carried their own three-arm switch — one
/// to tag a paired adapter in the picker, one to map onto
/// [Obd2ConnectTransport] for the trace log — and each had to remember
/// the `null` arm for an adapter the registry could not classify.
typedef BluetoothTransportDescriptor = ({
  /// Glyph for the transport.
  IconData icon,

  /// Resolves the localized transport tag. A function, not a string, so
  /// the descriptor stays const and the label follows the reader's
  /// locale (HARD RULE #1).
  String Function(AppLocalizations) label,

  /// The trace-log transport this maps to, or null when the transport is
  /// unknown and the trace must not claim one.
  Obd2ConnectTransport? connectTransport,
});

/// The descriptor for [transport], `null` included.
///
/// Total over `BluetoothTransport?` on purpose: an unfamiliar or
/// nameless adapter has no transport, and that case is the registry's
/// answer to give once rather than every caller's to remember. Adding a
/// value to [BluetoothTransport] makes this switch fail to compile,
/// which is the whole point of collecting it here.
BluetoothTransportDescriptor descriptorFor(BluetoothTransport? transport) =>
    switch (transport) {
      BluetoothTransport.classic => (
        icon: Icons.bluetooth,
        label: (l) => l.obd2TestAdapterTransportClassic,
        connectTransport: Obd2ConnectTransport.classic,
      ),
      BluetoothTransport.ble => (
        icon: Icons.bluetooth_audio,
        label: (l) => l.obd2TestAdapterTransportBle,
        connectTransport: Obd2ConnectTransport.ble,
      ),
      null => (
        icon: Icons.bluetooth_disabled,
        label: (l) => l.obd2TestAdapterTransportUnknown,
        connectTransport: null,
      ),
    };
