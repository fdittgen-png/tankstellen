// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'add_fill_up_screen.dart';

/// #3762 — the receipt-scan entry points of
/// [_AddFillUpScreenState], split out of `add_fill_up_screen.dart` as a
/// `part` mixin to satisfy the #1680 file-length ratchet. Move-only:
/// behaviour preserved verbatim.
mixin _AddFillUpScanFlow on _AddFillUpFormState {
  /// Bridge to the scan helpers in `fill_up_scan_handlers.dart`.
  /// Bundles the controllers + per-field setters the helpers need so
  /// the long async sequences live outside the screen file.
  FillUpScanHostState _buildScanHostState() => FillUpScanHostState(
        litersCtrl: _litersCtrl,
        costCtrl: _costCtrl,
        vehicleId: _vehicleId,
        readService: () => _scanService,
        writeService: (s) => _scanService = s,
        setScanning: (v) => setState(() => _scanning = v),
        setDate: (d) => setState(() => _date = d),
        setFuelType: (f) => setState(() => _fuelType = f),
        setScannedPricePerLiter: (p) =>
            setState(() => _scannedPricePerLiter = p),
        setLastScan: (o) => setState(() => _lastScan = o),
        isMounted: () => mounted,
        // #2275 — the active country drives the per-country validation
        // gate. Read defensively: a partially-initialised container
        // (some widget tests) must degrade to "no profile" rather than
        // throw before the scan even runs.
        activeCountry: _activeCountryCode(),
      );

  /// The active country code for OCR validation, or null when it can't
  /// be resolved (so the parser skips range-checking instead of the
  /// screen failing to build the scan host).
  String? _activeCountryCode() {
    try {
      return ref.read(activeCountryProvider).code;
    } catch (_) {
      return null;
    }
  }

  Future<void> _scanReceipt() => runReceiptScan(context, _buildScanHostState());

  /// #2687 — the manual, on-device "paste receipt text" entry point.
  /// Opens the paste dialog, parses the pasted text with the pure-Dart
  /// [EReceiptTextParser] (no camera, no cloud) and pre-fills the form
  /// through the SAME body the camera / share paths use. Never auto-saves.
  Future<void> _pasteReceiptText() =>
      runPasteReceiptText(context, _buildScanHostState());

  Future<void> _reportBadScan() async {
    final scan = _lastScan;
    if (scan == null) return;
    return reportBadReceiptScan(context, _buildScanHostState(), scan);
  }
}
