// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../../core/domain/exchange_rate_provider.dart';
import '../../../core/domain/money.dart';
import '../domain/entities/fill_up.dart';
import 'consumption_providers.dart';

/// Every exchange rate the fill-up history itself supplies (#4437 D).
///
/// Each one is per-record EVIDENCE — a card settlement the driver copied
/// off their statement, or a rate they typed in and that stays labelled
/// as such — directed, sourced and dated to its transaction. Nothing is
/// fetched and nothing is inferred from the active country, the profile
/// or today: a history with no settled fill yields an empty snapshot,
/// exactly the pre-#4437 state.
final settledExchangeRatesProvider = Provider<ExchangeRateSnapshot>(
  (ref) => settledRatesSnapshot(ref.watch(fillUpListProvider)),
);

/// Wires [settledExchangeRatesProvider] into the core
/// `exchangeRatesProvider` declaration — the extension point its library
/// doc names for "a user-entered rate". Every consumer then compares with
/// the rate's source and date in the explanation, and the snapshot's
/// freshness rule (`kExchangeRateMaxAge`) still refuses a rate too old to
/// decide a live ranking.
List<Override> exchangeRatesOverrides() => [
      exchangeRatesProvider
          .overrideWith((ref) => ref.watch(settledExchangeRatesProvider)),
    ];
