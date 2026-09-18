// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Which currency comparisons happen in, and the rates that get them
/// there (#4361, Epic #4358).
///
/// ## Why the snapshot ships empty
///
/// The app adopts no paid service, and no free feed it could depend on
/// publishes rates it would be honest to bake into a release build and
/// call current. So [exchangeRatesProvider] answers
/// [ExchangeRateSnapshot.empty] until a source exists, and the whole
/// stack behaves accordingly: a DE→DK list shows DKK and EUR prices side
/// by side, ranks by distance normally, and WITHHOLDS the claim that one
/// of them is the cheapest ([RefuelDecision.moneyRankingWithheld]).
///
/// That is the designed outcome, not a gap left open. The alternative —
/// a hard-coded rate that ages silently — produces a confident wrong
/// answer, which is the failure mode `docs/specs/refuel-economics.md` §5
/// names as costing more trust than the optimisation buys.
///
/// An override is all a rate source needs: a bundled table, a user-entered
/// rate, or a future provider overrides [exchangeRatesProvider] and every
/// consumer starts comparing, complete with the rate's source and date in
/// the explanation.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/price_formatter.dart';
import 'money.dart';

/// The ONE currency every money comparison is decided in: the active
/// country's.
///
/// The driver's own currency, not the selling station's — a German
/// driver comparing a Danish forecourt wants euros, and the Danish price
/// stays on screen beside the converted figure.
final comparisonCurrencyProvider = Provider<String>(
  (ref) => PriceFormatter.currencyCode,
);

/// The rates in force. See the library doc for why this is empty.
final exchangeRatesProvider = Provider<ExchangeRateSnapshot>(
  (ref) => const ExchangeRateSnapshot.empty(),
);
