// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../fleet/api.dart' show ParsedReceiptFacts;
import 'receipt_parser.dart' show ReceiptParseResult;

/// Maps a scan into the plain facts the fleet expense domain takes
/// (#4215).
///
/// It lives HERE, not in `fleet`, on purpose. `fill_ups` imports
/// `fleet` for the vehicle attribution a record is stamped with
/// (#4213), so `fleet` has to stay a leaf of the feature graph — a
/// `fleet -> receipts_ocr` import would drag it into the big cycle
/// that `feature_boundary_test`'s barrel-aware SCC gate (#4346)
/// rejects. `receipts_ocr -> fleet` closes nothing.
///
/// The direction also matches ownership: the scanner knows what it
/// read, the expense domain knows what an expense is, and this is the
/// one place that translates between them.
ParsedReceiptFacts parsedReceiptFactsOf(ReceiptParseResult parsed) =>
    ParsedReceiptFacts(
      stationName: parsed.stationName,
      date: parsed.date,
      fuelApiValue: parsed.fuelType?.apiValue,
      liters: parsed.liters,
      pricePerLiter: parsed.pricePerLiter,
      totalCost: parsed.totalCost,
      vatAmount: parsed.vatAmount,
      vatRate: parsed.vatRate,
      paymentReference: parsed.paymentReference,
      odometerKm: parsed.odometerKm,
      currency: parsed.currency,
    );
