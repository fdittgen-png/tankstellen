// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/guarded.dart';
import '../../../../core/permissions/permission_rationale_dialog.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../receipts_ocr/api.dart';
import 'fill_up_share_scan_handlers.dart';

/// Pure UI-side scan flows extracted from `add_fill_up_screen.dart`
/// (#563 extraction). Each entry-point takes a [BuildContext] plus
/// the host screen's mutable state (controllers + setters) so the
/// long async sequences live in one file instead of inflating the
/// screen.
///
/// This is intentionally not a class — every method is a top-level
/// function so the helper has no state of its own. The host
/// `_AddFillUpScreenState` keeps owning the controllers, the
/// `_lastScan`, `_date`, `_vehicleId`, `_fuelType`, and the
/// `_scanService` — and passes them in via the `state` parameter.
///
/// Lifting these flows out of the screen halves its line count; the
/// catches stay here, contained alongside the user-facing snackbars
/// they emit, and route their stack traces through `errorLogger`
/// (#3164).

/// Mutable surface the host screen exposes to the scan helpers. The
/// helpers only read/write through this struct so the screen can
/// continue to own all `setState` calls.
class FillUpScanHostState {
  final TextEditingController litersCtrl;
  final TextEditingController costCtrl;
  final String? vehicleId;

  /// Reads the current scan service (lazily instantiated on first
  /// scan) and writes it back when the helpers create one.
  final ReceiptScanService? Function() readService;
  final void Function(ReceiptScanService) writeService;

  /// Setters for the screen's per-field state. Each setter wraps
  /// `setState`; the helpers never touch widget state directly.
  final void Function(bool) setScanning;
  final void Function(DateTime) setDate;
  final void Function(FuelType) setFuelType;

  /// Stores the receipt-scanned unit price per litre on the host so the
  /// saved [FillUp] carries the exact quoted price (#2689) instead of
  /// only the `totalCost / liters` quotient.
  final void Function(double) setScannedPricePerLiter;
  final void Function(ReceiptScanOutcome) setLastScan;

  /// `mounted` predicate from the host state — checked after every
  /// `await` so we never call setState on a disposed screen.
  final bool Function() isMounted;

  /// ISO country code of the active region, threaded into the OCR so the
  /// per-country validation gate (#2275) can range-check the read. Null
  /// when unknown — the parser then skips range validation.
  final String? activeCountry;

  /// Station brand of the scanned receipt, when known — selects
  /// brand-aware parsing in the OCR config.
  final String? stationBrand;

  const FillUpScanHostState({
    required this.litersCtrl,
    required this.costCtrl,
    required this.vehicleId,
    required this.readService,
    required this.writeService,
    required this.setScanning,
    required this.setDate,
    required this.setFuelType,
    required this.setScannedPricePerLiter,
    required this.setLastScan,
    required this.isMounted,
    this.activeCountry,
    this.stationBrand,
  });
}

/// Receipt scan flow — opens the camera, runs ML Kit, fills the form
/// from the parsed result, and shows a success / no-data / error
/// snackbar. Caches the [ReceiptScanOutcome] back into the host so the
/// "Report scan error" affordance can ship the photo on demand.
Future<void> runReceiptScan(
  BuildContext context,
  FillUpScanHostState state,
) async {
  state.setScanning(true);
  final l = AppLocalizations.of(context);
  try {
    var service = state.readService();
    if (service == null) {
      service = ReceiptScanService();
      state.writeService(service);
    }
    // #3872 (GDPR) — the one-time camera rationale precedes the FIRST OS
    // camera prompt, which `ImagePicker` raises on first use. Continue-only:
    // the scan always follows.
    await PermissionRationaleDialog.show(
      context,
      kind: PermissionRationaleKind.camera,
      storage: ProviderScope.containerOf(context, listen: false)
          .read(settingsStorageProvider),
    );
    if (!context.mounted || !state.isMounted()) return;
    // #2273 — thread the active country/brand so the parser reads the
    // receipt in the right currency (GBP/£/p, kr, $ …).
    final outcome = await service.scanReceipt(
      country: state.activeCountry,
      brand: state.stationBrand,
    );
    if (outcome == null || !state.isMounted()) return;

    if (!outcome.parse.hasData) {
      if (context.mounted) {
        SnackBarHelper.show(context, l.scanReceiptNoData);
      }
      return;
    }

    applyReceiptOutcome(state, outcome);

    if (state.isMounted() && context.mounted) {
      SnackBarHelper.show(context, receiptScanSuccessMessage(l, outcome));
    }
  } catch (e, st) {
    logFailure(e, st, where: 'runReceiptScan: receipt scan failed');
    if (state.isMounted() && context.mounted) {
      SnackBarHelper.showError(context, l.scanReceiptFailed(e.toString()));
    }
  } finally {
    if (state.isMounted()) state.setScanning(false);
  }
}

/// Opens the [BadScanReportSheet] for a receipt scan whose values the
/// user has already corrected on the form (#751 / #952). Pre-fills the
/// final user-entered values so the diff is captured against the OCR
/// output.
Future<void> reportBadReceiptScan(
  BuildContext context,
  FillUpScanHostState state,
  ReceiptScanOutcome scan,
) async {
  final liters = double.tryParse(state.litersCtrl.text.replaceAll(',', '.'));
  final cost = double.tryParse(state.costCtrl.text.replaceAll(',', '.'));
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => BadScanReportSheet(
      scan: scan,
      enteredLiters: liters,
      enteredTotalCost: cost,
      appVersion: AppConstants.appVersion,
    ),
  );
}
