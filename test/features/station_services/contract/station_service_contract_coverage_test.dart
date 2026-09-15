// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Every registered country is accounted for by the contract (#4157).
///
/// The acceptance criterion is "a new country cannot be registered
/// without passing it". That cannot mean "a test somewhere exists",
/// because the failure mode is precisely that nobody remembers to write
/// one. So the registry is the source of truth and this file is the
/// ledger: a country is either **covered** by a contract case, or
/// **exempt** with a reason and a linked issue. There is no third state,
/// and a country that falls into none fails here.
///
/// Deliberately NOT a skip. `feedback_fake_services_false_green` and
/// `source_scanning_tests_dont_execute` are the same lesson twice: a
/// test that quietly does nothing looks identical to a test that passes.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/country_service_registry.dart';

/// Countries driven by a recorded real response through the real
/// service, with the file that does it.
const Map<String, String> kContractCovered = {
  'AT': 'austria/econtrol_contract_test.dart',
  'ES': 'spain/miteco_contract_test.dart',
};

/// Countries not yet driven by the contract, each with the reason and
/// the issue that tracks closing the gap.
///
/// An entry here is a **statement**, not a silence. Adding one is a
/// deliberate act that a reviewer can see.
const Map<String, String> kContractExempt = {
  'AU': 'provider retired, capability declares price:false — #804',
  'AR': 'no recorded response checked in yet — #4180',
  'CL': 'no recorded response checked in yet — #4180',
  'DE': 'no recorded response checked in yet — #4180',
  'DK': 'no recorded response checked in yet — #4180',
  'FR': 'no recorded response checked in yet — #4180',
  'GB': 'no recorded response checked in yet — #4180',
  'GR': 'no recorded response checked in yet — #4180',
  'IT': 'no recorded response checked in yet — #4180',
  'KR': 'no recorded response checked in yet — #4180',
  'LU': 'no recorded response checked in yet — #4180',
  'MX': 'no recorded response checked in yet — #4180',
  'PT': 'no recorded response checked in yet — #4180',
  'RO': 'no recorded response checked in yet — #4180',
  'SI': 'no recorded response checked in yet — #4180',
};

void main() {
  final registered = CountryServiceRegistry.registeredCountryCodes;

  test('every registered country is covered or explicitly exempt', () {
    final accounted = {...kContractCovered.keys, ...kContractExempt.keys};
    final unaccounted = registered.difference(accounted);
    expect(unaccounted, isEmpty,
        reason: 'These countries are registered and the contract says '
            'nothing about them: $unaccounted.\n'
            'Add a contract case (preferred) or an entry in '
            'kContractExempt with a reason and an issue number.');
  });

  test('the ledger lists no country that is not registered', () {
    // A stale entry is how a ledger stops meaning anything: it makes the
    // covered set look bigger than it is.
    final accounted = {...kContractCovered.keys, ...kContractExempt.keys};
    expect(accounted.difference(registered), isEmpty);
  });

  test('every exemption states a reason AND an issue', () {
    for (final entry in kContractExempt.entries) {
      expect(entry.value.trim(), isNotEmpty, reason: entry.key);
      expect(entry.value, contains('#'),
          reason: '${entry.key}: an exemption without an issue is a '
              'silence with extra steps');
    }
  });

  test('every covered country names a file that exists', () {
    for (final entry in kContractCovered.entries) {
      final f = File('test/features/station_services/${entry.value}');
      expect(f.existsSync(), isTrue,
          reason: '${entry.key} claims ${entry.value}, which is not there');
    }
  });

  test('coverage only ever grows', () {
    // The ratchet, applied to the contract itself: a country may move
    // from exempt to covered, never back. Lowering this number means
    // someone deleted a contract case.
    const baseline = 2;
    expect(kContractCovered.length, greaterThanOrEqualTo(baseline),
        reason: 'contract coverage went DOWN — a country lost its case');
  });
}
