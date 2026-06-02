// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/error_logger.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/receipt_scan_service.dart';
import '../../providers/pending_shared_receipt_provider.dart';
import 'fill_up_scan_handlers.dart';

/// Shared receipt-prefill body + the path-fed share-scan sibling
/// (#2734 — foundation for the on-device e-receipt epic #2687).
///
/// Split out of `fill_up_scan_handlers.dart` so that file stays under
/// the 400-line norm (#1680). The camera-owning [runReceiptScan] (in the
/// sibling file) and the camera-free [runSharedReceiptScan] (here) both
/// prefill the form through the SAME [applyReceiptOutcome] body, so a
/// share-intent receipt fills the form identically to a camera scan.

/// Applies a parsed [ReceiptScanOutcome] to the host form: liters /
/// cost controllers, the receipt date, the scanned unit price (#2689),
/// the fuel type (only when no vehicle is bound, #698), and caches the
/// outcome back into the host so the "Report scan error" affordance can
/// ship the photo on demand.
///
/// Extracted (#2734) from [runReceiptScan] so the camera path and the
/// path-fed share-scan sibling [runSharedReceiptScan] prefill from one
/// shared, context-free body — guaranteeing zero prefill drift between
/// the two flows. Pure field mutation: shows no UI, never throws on a
/// well-formed outcome, and is a no-op for the fields the parser left
/// null.
///
/// Caller contract: only invoke when `outcome.parse.hasData` is true —
/// the snackbar mapping (`scanReceiptNoData` vs `scanReceiptSuccess`)
/// stays with the flow entry-points so each can drive its own UI.
void applyReceiptOutcome(FillUpScanHostState state, ReceiptScanOutcome outcome) {
  final result = outcome.parse;
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
}

/// Builds the "receipt scanned" success message, prepending the detected
/// station name (#2734) when the parser recognised one. The station name
/// is a proper noun (brand) so it is surfaced inline without its own ARB
/// key — non-blocking and informational, it never alters the numeric
/// prefill. Both [runReceiptScan] and [runSharedReceiptScan] route their
/// success snackbar through this so the station hint reaches both flows.
String receiptScanSuccessMessage(
  AppLocalizations? l,
  ReceiptScanOutcome outcome,
) {
  final base = l?.scanReceiptSuccess ??
      'Receipt scanned — verify values. Tap "Report scan error" '
          'below if anything is off.';
  final station = outcome.parse.stationName?.trim();
  if (station == null || station.isEmpty) return base;
  // i18n-ignore: station name is a proper noun / brand surfaced inline (#2734)
  return '$station — $base';
}

/// Path-fed sibling of [runReceiptScan] (#2734 — foundation for the
/// on-device e-receipt epic #2687). Instead of opening the camera it
/// OCRs + parses an already-captured receipt photo at [path] via
/// [ReceiptScanService.parseReceiptImage], then prefills the form through
/// the SAME [applyReceiptOutcome] body — so a share-intent receipt fills
/// the form identically to a camera scan. Mirrors [runReceiptScan]'s
/// loading / no-data / success / error handling exactly, reusing the same
/// `scanReceiptSuccess` / `scanReceiptNoData` / `scanReceiptFailed` keys.
///
/// Never throws: [ReceiptScanService.parseReceiptImage] degrades to null
/// on an unreadable image and the catch maps any failure to the error
/// snackbar (#2349 fault-injection contract).
Future<void> runSharedReceiptScan(
  BuildContext context,
  FillUpScanHostState state,
  String path,
) async {
  state.setScanning(true);
  final l = AppLocalizations.of(context);
  try {
    var service = state.readService();
    if (service == null) {
      service = ReceiptScanService();
      state.writeService(service);
    }
    // Camera-free entry — the photo is already on disk (share intent /
    // gallery). #2273 — thread the active country/brand identically so
    // the parser reads the receipt in the right currency.
    final outcome = await service.parseReceiptImage(
      path,
      country: state.activeCountry,
      brand: state.stationBrand,
    );
    if (outcome == null || !state.isMounted()) return;

    if (!outcome.parse.hasData) {
      if (context.mounted) {
        SnackBarHelper.show(
          context,
          l?.scanReceiptNoData ?? 'No receipt data found — try again',
        );
      }
      return;
    }

    applyReceiptOutcome(state, outcome);

    if (state.isMounted() && context.mounted) {
      SnackBarHelper.show(context, receiptScanSuccessMessage(l, outcome));
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

/// #2735 — drains the inbound-share receipt path stashed by
/// `ShareReceiptHandler` and runs [runSharedReceiptScan] on the next
/// frame, prefilling the host form from the shared receipt's OCR. Called
/// from `AddFillUpScreen.initState`; a no-op when nothing was shared (the
/// common case of opening the form manually).
///
/// Lives here, not on the screen, so the screen file stays close to its
/// grandfathered size (#1680). [ref] reads the stash via `consumeDeferred`
/// — `initState` is a Riverpod-locked phase that forbids the synchronous
/// notifier write `consume` would do (the same constraint the router
/// redirect hits); the deferred clear runs on a microtask so a rebuild
/// can't re-scan. [buildHost] is the screen's `_buildScanHostState`, fed
/// to the never-throws (#2349) [runSharedReceiptScan] after first frame
/// so `context` carries a live `ScaffoldMessenger` and the form is built.
void scheduleSharedReceiptScanIfPending(
  WidgetRef ref,
  BuildContext context,
  FillUpScanHostState Function() buildHost,
  bool Function() isMounted,
) {
  String? path;
  try {
    path =
        ref.read(pendingSharedReceiptProvider.notifier).consumeDeferred();
  } catch (e, st) {
    unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {
      'where': 'AddFillUp: pending shared-receipt read failed',
    }));
    return;
  }
  if (path == null) return;
  final sharedPath = path;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!isMounted()) return;
    unawaited(runSharedReceiptScan(context, buildHost(), sharedPath));
  });
}
