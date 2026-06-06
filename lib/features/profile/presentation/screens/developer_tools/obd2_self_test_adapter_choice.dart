// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../l10n/app_localizations.dart';

part 'obd2_self_test_adapter_choice.g.dart';

/// A paired OBD2 adapter the user can target with the self-test (#2938):
/// the stable MAC the app reconnects by + a display name (the advertised
/// adapter name, falling back to the MAC for legacy profiles).
class Obd2PairedAdapter {
  const Obd2PairedAdapter({required this.mac, required this.name});

  final String mac;
  final String name;
}

/// The MAC the user picked for the next self-test run (#2938). `null` ⇒ the
/// "Scan for adapter" fallback (the legacy blind scan). The family is keyed by
/// the [defaultMac] (the active vehicle's paired adapter) so the dropdown
/// starts on the sensible default without an init-time write — selecting the
/// scan fallback explicitly is a [set]`(null)`.
///
/// `keepAlive` so the choice survives the health screen rebuilding on every
/// diagnostics-collector tick (an autoDispose notifier would reset mid-run).
@Riverpod(keepAlive: true)
class Obd2SelfTestSelectedAdapter extends _$Obd2SelfTestSelectedAdapter {
  @override
  String? build(String? defaultMac) => defaultMac;

  /// Pick [mac] (or `null` for the scan fallback) as the next run's target.
  void set(String? mac) => state = mac;
}

/// The adapter-choice control above the Run button (#2938). A dropdown of the
/// user's paired adapters plus a "Scan for adapter" fallback. Hidden entirely
/// when no paired adapter exists — there is nothing to choose, and the run
/// then takes the legacy blind scan (the original behaviour).
class Obd2SelfTestAdapterChoice extends StatelessWidget {
  const Obd2SelfTestAdapterChoice({
    super.key,
    required this.adapters,
    required this.selectedMac,
    required this.onChanged,
    this.enabled = true,
  });

  final List<Obd2PairedAdapter> adapters;

  /// The currently selected MAC, or `null` for the scan fallback.
  final String? selectedMac;

  final ValueChanged<String?> onChanged;
  final bool enabled;

  /// Sentinel `DropdownMenuItem.value` for the scan fallback (a dropdown
  /// cannot use `null` as a value alongside real values without ambiguity).
  static const String _scanSentinel = '__scan__';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (adapters.isEmpty) {
      // No paired adapter to choose — the run falls back to the blind scan.
      return const SizedBox.shrink();
    }
    final scanLabel = l?.obd2TestAdapterScanOption ?? 'Scan for adapter';
    return Padding(
      key: const ValueKey('obd2-self-test-adapter-choice'),
      padding: const EdgeInsets.only(top: 4),
      child: DropdownButtonFormField<String>(
        key: const ValueKey('obd2-self-test-adapter-dropdown'),
        initialValue: selectedMac ?? _scanSentinel,
        decoration: InputDecoration(
          labelText: l?.obd2TestAdapterLabel ?? 'Adapter to test',
          prefixIcon: const Icon(Icons.bluetooth),
        ),
        items: [
          for (final a in adapters)
            DropdownMenuItem<String>(
              value: a.mac,
              child: Text(a.name, overflow: TextOverflow.ellipsis),
            ),
          DropdownMenuItem<String>(
            value: _scanSentinel,
            child: Text(scanLabel, overflow: TextOverflow.ellipsis),
          ),
        ],
        onChanged: enabled
            ? (value) =>
                onChanged(value == _scanSentinel ? null : value)
            : null,
      ),
    );
  }
}
