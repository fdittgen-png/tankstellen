// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/feedback/github_issue_reporter.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../data/receipt_scan_service.dart';
import '../screens/pump_display_camera_screen.dart';
import 'bad_scan_report_sheet.dart';
import 'pump_scan_failure_sheet.dart';

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
/// Lifting these flows out of the screen halves its line count and
/// drops the ad-hoc `// ignore: unused_catch_stack` noise from the
/// orchestration layer; the catches stay here, contained alongside
/// the user-facing snackbars they emit.

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
  final void Function(bool) setScanningPump;
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

  /// Opens the pump-display capture surface — the #1868 in-app camera
  /// screen with the framing reticle — and returns the capture (photo
  /// path + the normalized reticle rect the user framed, #2275), or
  /// null when the user cancels or the camera is unavailable. A seam so
  /// widget tests can stub the capture.
  final Future<PumpCaptureResult?> Function(BuildContext) capturePumpImage;

  /// ISO country code of the active region, threaded into the OCR so the
  /// per-country validation gate (#2275) can range-check the read. Null
  /// when unknown — the parser then skips range validation.
  final String? activeCountry;

  /// Station brand of the scanned pump, when known — selects the brand
  /// template (FR/Tokheim pump-display ROIs) in the OCR config.
  final String? stationBrand;

  const FillUpScanHostState({
    required this.litersCtrl,
    required this.costCtrl,
    required this.vehicleId,
    required this.readService,
    required this.writeService,
    required this.setScanning,
    required this.setScanningPump,
    required this.setDate,
    required this.setFuelType,
    required this.setScannedPricePerLiter,
    required this.setLastScan,
    required this.isMounted,
    required this.capturePumpImage,
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
    // #2273 — thread the active country/brand so the parser reads the
    // receipt in the right currency (GBP/£/p, kr, $ …), mirroring how
    // the pump path threads them into parsePumpDisplayImage.
    final outcome = await service.scanReceipt(
      country: state.activeCountry,
      brand: state.stationBrand,
    );
    if (outcome == null || !state.isMounted()) return;
    final result = outcome.parse;

    if (!result.hasData) {
      if (context.mounted) {
        SnackBarHelper.show(
          context,
          l?.scanReceiptNoData ?? 'No receipt data found — try again',
        );
      }
      return;
    }

    if (result.liters != null) {
      state.litersCtrl.text = result.liters!.toStringAsFixed(2);
    }
    if (result.totalCost != null) {
      state.costCtrl.text = result.totalCost!.toStringAsFixed(2);
    }
    if (result.date != null) {
      state.setDate(result.date!);
    }
    // #2689 — keep the exact scanned unit price so the saved FillUp
    // preserves it verbatim rather than re-deriving totalCost / liters
    // (which rounds differently and drifts if either field is edited).
    if (result.pricePerLiter != null) {
      state.setScannedPricePerLiter(result.pricePerLiter!);
    }
    // Only pre-select the fuel when there is no vehicle bound — the
    // vehicle's configured fuel always wins (#698 single source of
    // truth for fuel).
    if (result.fuelType != null && state.vehicleId == null) {
      state.setFuelType(result.fuelType!);
    }
    state.setLastScan(outcome);

    if (state.isMounted() && context.mounted) {
      SnackBarHelper.show(
        context,
        l?.scanReceiptSuccess ??
            'Receipt scanned — verify values. Tap "Report scan error" '
                'below if anything is off.',
      );
    }
  } catch (e, st) { // ignore: unused_catch_stack
    if (state.isMounted() && context.mounted) {
      SnackBarHelper.showError(
        context,
        l?.scanReceiptFailed(e.toString()) ?? 'Scan failed: $e',
      );
    }
  } finally {
    if (state.isMounted()) state.setScanning(false);
  }
}

/// Pump-display scan flow (#598). Mirrors [runReceiptScan] but on
/// failure routes into [PumpScanFailureSheet] (#953) instead of
/// dropping the photo silently.
Future<void> runPumpDisplayScan(
  BuildContext context,
  FillUpScanHostState state,
) async {
  state.setScanningPump(true);
  final l = AppLocalizations.of(context);
  try {
    var service = state.readService();
    if (service == null) {
      service = ReceiptScanService();
      state.writeService(service);
    }
    // #1868 — capture through the in-app camera screen (framing
    // reticle), then OCR + parse the returned photo. #2275 — pass the
    // reticle ROI so the OCR crops to the framed readout first, and the
    // active country/brand so the validation gate can range-check.
    final capture = await state.capturePumpImage(context);
    if (capture == null || !state.isMounted()) return;
    final outcome = await service.parsePumpDisplayImage(
      capture.path,
      country: state.activeCountry,
      brand: state.stationBrand,
      roi: capture.roi,
    );
    if (outcome == null || !state.isMounted()) return;
    // #2275 — an over-glared frame gets a "re-angle" prompt, not the
    // generic failure sheet: the fix is a different shooting angle.
    if (outcome.glareRejected) {
      await state.readService()?.deleteCapturedImage(outcome.imagePath);
      if (state.isMounted() && context.mounted) {
        SnackBarHelper.show(
          context,
          l?.scanPumpGlare ??
              'Too much glare on the display — try again at a slight '
                  'angle so the numbers aren\'t washed out.',
        );
      }
      return;
    }
    final result = outcome.parse;
    if (!result.hasUsableData) {
      if (context.mounted) {
        await _showPumpScanFailureSheet(context, state, outcome);
      }
      return;
    }
    if (result.liters != null) {
      state.litersCtrl.text = result.liters!.toStringAsFixed(2);
    }
    if (result.totalCost != null) {
      state.costCtrl.text = result.totalCost!.toStringAsFixed(2);
    }
    if (state.isMounted() && context.mounted) {
      SnackBarHelper.show(
        context,
        l?.scanPumpSuccess ?? 'Pump display scanned — verify the values.',
      );
    }
  } catch (e, st) { // ignore: unused_catch_stack
    if (state.isMounted() && context.mounted) {
      SnackBarHelper.showError(
        context,
        l?.scanPumpFailed(e.toString()) ?? 'Pump scan failed: $e',
      );
    }
  } finally {
    if (state.isMounted()) state.setScanningPump(false);
  }
}

/// Opens the failure-flow bottom sheet for an unreadable pump-display
/// scan (#953). The sheet is dismissable; the action the user picks
/// determines the next step:
///   - correctManually: close, leave the form untouched.
///   - report: open [BadScanReportSheet] with [ScanKind.pumpDisplay].
///   - removePhoto: delete the temp file and forget the scan.
Future<void> _showPumpScanFailureSheet(
  BuildContext context,
  FillUpScanHostState state,
  PumpDisplayScanOutcome outcome,
) async {
  final action = await showModalBottomSheet<PumpScanFailureAction>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const PumpScanFailureSheet(),
  );
  if (!state.isMounted()) return;
  switch (action) {
    case PumpScanFailureAction.report:
      if (context.mounted) {
        await reportBadPumpScan(context, state, outcome);
      }
      break;
    case PumpScanFailureAction.removePhoto:
      await state.readService()?.deleteCapturedImage(outcome.imagePath);
      break;
    case PumpScanFailureAction.correctManually:
    case null:
      // Sheet dismissed or "Correct manually" — keep the photo on
      // disk so the user can still hit "Report scan error" via the
      // existing affordance below the form. (The button currently
      // surfaces only for receipt scans; pump-display reports are
      // accessible via the failure sheet itself.)
      break;
  }
}

/// Opens the [BadScanReportSheet] for a failed pump-display scan
/// (#953). Pre-fills the entered liters/cost so the GitHub issue
/// captures the user's typed values alongside the OCR output.
Future<void> reportBadPumpScan(
  BuildContext context,
  FillUpScanHostState state,
  PumpDisplayScanOutcome outcome,
) async {
  final liters =
      double.tryParse(state.litersCtrl.text.replaceAll(',', '.'));
  final cost = double.tryParse(state.costCtrl.text.replaceAll(',', '.'));
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => BadScanReportSheet(
      kind: ScanKind.pumpDisplay,
      pumpScan: outcome,
      enteredLiters: liters,
      enteredTotalCost: cost,
      appVersion: AppConstants.appVersion,
    ),
  );
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
  final liters =
      double.tryParse(state.litersCtrl.text.replaceAll(',', '.'));
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
