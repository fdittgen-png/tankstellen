// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'obd2_adapter_picker.dart';

/// #3760 — the picker sheet's widget tree (per-phase body + candidate
/// tiles), split out of `obd2_adapter_picker.dart` as a `part` mixin
/// (move-only, behaviour preserved). Constrained `on`
/// [_Obd2AdapterPickerFlow] so it renders the same private phase /
/// candidate fields and dispatches back into `_connect` / `_startScan`.
mixin _Obd2AdapterPickerBody
    on ConsumerState<Obd2AdapterPickerSheet>, _Obd2AdapterPickerFlow {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.obdPickerTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildBody(l),
          ],
        ),
      ),
    );
  }

  /// #3103 — one tile shape for both sections. A recognized candidate shows
  /// its matched profile name; an unrecognized one (empty placeholder profile)
  /// shows the device's own advertised name + a muted "tap to try" hint.
  Widget _candidateTile(ResolvedObd2Candidate c, AppLocalizations l) {
    final subtitle = c.recognized
        ? '${c.profile.displayName} · ${c.candidate.rssi} dBm'
        : '${l.obd2PickerTapToTry} · '
            '${c.candidate.rssi} dBm';
    return ListTile(
      key: Key('obdPickerItem_${c.candidate.deviceId}'),
      leading: Icon(
        c.recognized ? Icons.bluetooth : Icons.bluetooth_searching,
      ),
      title: Text(c.candidate.deviceName.isEmpty
          ? c.profile.displayName
          : c.candidate.deviceName),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _connect(c),
    );
  }

  Widget _buildBody(AppLocalizations l) {
    switch (_phase) {
      case _Phase.scanning:
        return Column(
          key: const Key('obdPickerScanning'),
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(l.obdPickerScanning),
          ],
        );
      case _Phase.selecting:
        // Zero candidates: the diagnostic empty state resolves WHY.
        if (_candidates.isEmpty) return Obd2ScanEmptyState(onRetry: _startScan);
        // #3103 — recognized adapters first, then NAMED-but-unrecognized
        // devices under an "other devices" header so discovery surfaces ALL
        // adapters, not just catalog-known ones.
        final recognized = [for (final c in _candidates) if (c.recognized) c];
        final unrecognized = [
          for (final c in _candidates)
            if (!c.recognized) c,
        ];
        return Column(
          key: const Key('obdPickerSelecting'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final c in recognized) _candidateTile(c, l),
            if (unrecognized.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  l.obd2PickerOtherDevices,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              for (final c in unrecognized) _candidateTile(c, l),
            ],
            if (!_supportsClassicDiscovery)
              Padding(
                key: const Key('obdPickerBleOnlyNotice'),
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
                child: Text(
                  l.obd2PickerBleOnlyNotice,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        );
      case _Phase.connecting:
        return Column(
          key: const Key('obdPickerConnecting'),
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(l.obdPickerConnecting),
            // #3181 — while a FIRST-connect setNotify is in flight the OS
            // pairing dialog may be waiting for the user; tell them to
            // confirm it instead of letting the spinner look hung.
            ValueListenableBuilder<bool>(
              valueListenable: Obd2PairingMode.pairingWaitPending,
              builder: (context, pending, _) {
                if (!pending) return const SizedBox.shrink();
                return Padding(
                  key: const Key('obdPickerPairingHint'),
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    l.obd2PairingConfirmHint,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ],
        );
      case _Phase.error:
        // A scan TIMEOUT is not an error to explain — it is an empty
        // result to diagnose. Route it to the readiness-probing empty
        // state, which names the actual blocker (radio off mid-scan,
        // Android location services off, or genuinely nothing in
        // range) instead of a generic "nothing found" sentence.
        if (_error is Obd2ScanTimeout) {
          return Obd2ScanEmptyState(onRetry: _startScan);
        }
        return Obd2ScanErrorState(error: _error, onRetry: _startScan);
      case _Phase.blocked:
        // Pre-flight found a non-promptable blocker — no scan ran.
        return Obd2ScanEmptyState(onRetry: _startScan);
    }
  }
}
