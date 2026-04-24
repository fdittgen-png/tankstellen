import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/report/domain/entities/report_type.dart';

/// Tests for `ReportType` enum — Refs #561.
///
/// Covers:
///   - `apiValue` mapping (constructor arg)
///   - `needsPrice` / `needsText` predicate buckets
///   - `routesToGitHub` / `isTankerkoenigSupported` routing predicates
///   - `fuelTypeColumnValue` Supabase column mapping
///   - `visibleForCountry` country gating (#484)
///   - `displayName(null)` English fallback path (l10n-free)
///
/// `displayName(AppLocalizations)` with a real localisation delegate is
/// covered implicitly by widget tests that pump the report screen — here
/// we only assert the fallback branch so the unit test stays pure.
void main() {
  group('apiValue', () {
    test('wrongE5 → wrongPetrolPremium', () {
      expect(ReportType.wrongE5.apiValue, 'wrongPetrolPremium');
    });

    test('wrongE10 → wrongPetrolPremiumE10', () {
      expect(ReportType.wrongE10.apiValue, 'wrongPetrolPremiumE10');
    });

    test('wrongDiesel → wrongDiesel', () {
      expect(ReportType.wrongDiesel.apiValue, 'wrongDiesel');
    });

    test('wrongE85 → wrongPetrolE85', () {
      expect(ReportType.wrongE85.apiValue, 'wrongPetrolE85');
    });

    test('wrongE98 → wrongPetrolPremiumE98', () {
      expect(ReportType.wrongE98.apiValue, 'wrongPetrolPremiumE98');
    });

    test('wrongLpg → wrongLpg', () {
      expect(ReportType.wrongLpg.apiValue, 'wrongLpg');
    });

    test('wrongStatusOpen → wrongStatusOpen', () {
      expect(ReportType.wrongStatusOpen.apiValue, 'wrongStatusOpen');
    });

    test('wrongStatusClosed → wrongStatusClosed', () {
      expect(ReportType.wrongStatusClosed.apiValue, 'wrongStatusClosed');
    });

    test('wrongName → wrongName', () {
      expect(ReportType.wrongName.apiValue, 'wrongName');
    });

    test('wrongAddress → wrongAddress', () {
      expect(ReportType.wrongAddress.apiValue, 'wrongAddress');
    });

    test('all 10 apiValues are unique', () {
      final values = ReportType.values.map((e) => e.apiValue).toSet();
      expect(values.length, ReportType.values.length);
    });
  });

  group('needsPrice', () {
    const priceTypes = <ReportType>[
      ReportType.wrongE5,
      ReportType.wrongE10,
      ReportType.wrongDiesel,
      ReportType.wrongE85,
      ReportType.wrongE98,
      ReportType.wrongLpg,
    ];

    const nonPriceTypes = <ReportType>[
      ReportType.wrongStatusOpen,
      ReportType.wrongStatusClosed,
      ReportType.wrongName,
      ReportType.wrongAddress,
    ];

    for (final t in priceTypes) {
      test('$t needsPrice = true', () {
        expect(t.needsPrice, isTrue);
      });
    }

    for (final t in nonPriceTypes) {
      test('$t needsPrice = false', () {
        expect(t.needsPrice, isFalse);
      });
    }

    test('exactly 6 price types', () {
      final count = ReportType.values.where((e) => e.needsPrice).length;
      expect(count, 6);
    });
  });

  group('needsText', () {
    const textTypes = <ReportType>[
      ReportType.wrongName,
      ReportType.wrongAddress,
    ];

    for (final t in ReportType.values) {
      final shouldBeText = textTypes.contains(t);
      test('$t needsText = $shouldBeText', () {
        expect(t.needsText, shouldBeText);
      });
    }

    test('exactly 2 text types', () {
      final count = ReportType.values.where((e) => e.needsText).length;
      expect(count, 2);
    });
  });

  group('routesToGitHub (#508)', () {
    const gitHubTypes = <ReportType>[
      ReportType.wrongName,
      ReportType.wrongAddress,
    ];

    for (final t in ReportType.values) {
      final shouldRoute = gitHubTypes.contains(t);
      test('$t routesToGitHub = $shouldRoute', () {
        expect(t.routesToGitHub, shouldRoute);
      });
    }

    test('routesToGitHub matches needsText — metadata reports route to GitHub',
        () {
      for (final t in ReportType.values) {
        expect(
          t.routesToGitHub,
          t.needsText,
          reason: '$t should route to GitHub iff it needs free-text input',
        );
      }
    });
  });

  group('isTankerkoenigSupported', () {
    const supported = <ReportType>[
      ReportType.wrongE5,
      ReportType.wrongE10,
      ReportType.wrongDiesel,
      ReportType.wrongStatusOpen,
      ReportType.wrongStatusClosed,
    ];

    for (final t in ReportType.values) {
      final isSupported = supported.contains(t);
      test('$t isTankerkoenigSupported = $isSupported', () {
        expect(t.isTankerkoenigSupported, isSupported);
      });
    }

    test('exactly 5 Tankerkoenig-supported types (the original set)', () {
      final count = ReportType.values
          .where((e) => e.isTankerkoenigSupported)
          .length;
      expect(count, 5);
    });

    test('extended price types (E85, E98, LPG) are NOT Tankerkoenig-supported',
        () {
      expect(ReportType.wrongE85.isTankerkoenigSupported, isFalse);
      expect(ReportType.wrongE98.isTankerkoenigSupported, isFalse);
      expect(ReportType.wrongLpg.isTankerkoenigSupported, isFalse);
    });
  });

  group('fuelTypeColumnValue (Supabase mapping)', () {
    const expected = <ReportType, String>{
      ReportType.wrongE5: 'e5',
      ReportType.wrongE10: 'e10',
      ReportType.wrongDiesel: 'diesel',
      ReportType.wrongE85: 'e85',
      ReportType.wrongE98: 'e98',
      ReportType.wrongLpg: 'lpg',
      ReportType.wrongStatusOpen: 'status_open',
      ReportType.wrongStatusClosed: 'status_closed',
      ReportType.wrongName: 'name',
      ReportType.wrongAddress: 'address',
    };

    for (final entry in expected.entries) {
      test('${entry.key} → ${entry.value}', () {
        expect(entry.key.fuelTypeColumnValue, entry.value);
      });
    }

    test('covers every enum value (exhaustive switch)', () {
      // If a new ReportType is added without a fuelTypeColumnValue branch,
      // Dart's exhaustiveness check fires at compile time. This test also
      // fails if the map above drifts out of sync with the enum.
      for (final t in ReportType.values) {
        expect(
          expected.containsKey(t),
          isTrue,
          reason: 'Missing fuelTypeColumnValue expectation for $t',
        );
      }
    });

    test('all column values are unique (no analytics aliasing)', () {
      final values =
          ReportType.values.map((e) => e.fuelTypeColumnValue).toSet();
      expect(values.length, ReportType.values.length);
    });
  });

  group('visibleForCountry', () {
    test('DE → all 10 report types', () {
      final types = ReportType.visibleForCountry('DE');
      expect(types, ReportType.values);
      expect(types.length, 10);
    });

    test('FR → metadata-only (name + address)', () {
      final types = ReportType.visibleForCountry('FR');
      expect(types, const [ReportType.wrongName, ReportType.wrongAddress]);
    });

    test('IT → metadata-only', () {
      expect(
        ReportType.visibleForCountry('IT'),
        const [ReportType.wrongName, ReportType.wrongAddress],
      );
    });

    test('ES → metadata-only', () {
      expect(
        ReportType.visibleForCountry('ES'),
        const [ReportType.wrongName, ReportType.wrongAddress],
      );
    });

    test('empty country code → metadata-only fallback', () {
      expect(
        ReportType.visibleForCountry(''),
        const [ReportType.wrongName, ReportType.wrongAddress],
      );
    });

    test('lowercase "de" does NOT match — case-sensitive ISO codes', () {
      // The app normalises to upper-case ISO-3166 codes upstream; a
      // lowercase value here means the caller forgot to normalise.
      // Falling back to metadata-only is the safe default (no
      // Tankerkoenig attempt against a non-DE station).
      expect(
        ReportType.visibleForCountry('de'),
        const [ReportType.wrongName, ReportType.wrongAddress],
      );
    });

    test('non-DE country list only contains GitHub-routed types', () {
      final types = ReportType.visibleForCountry('FR');
      for (final t in types) {
        expect(t.routesToGitHub, isTrue);
      }
    });
  });

  group('displayName (null l10n fallback)', () {
    const expected = <ReportType, String>{
      ReportType.wrongE5: 'Prix Super E5 incorrect',
      ReportType.wrongE10: 'Prix Super E10 incorrect',
      ReportType.wrongDiesel: 'Prix Diesel incorrect',
      ReportType.wrongE85: 'Wrong E85 price',
      ReportType.wrongE98: 'Wrong Super 98 price',
      ReportType.wrongLpg: 'Wrong LPG price',
      ReportType.wrongStatusOpen: 'Shown as open, but closed',
      ReportType.wrongStatusClosed: 'Shown as closed, but open',
      ReportType.wrongName: 'Wrong station name',
      ReportType.wrongAddress: 'Wrong address',
    };

    for (final entry in expected.entries) {
      test('${entry.key} fallback label', () {
        expect(entry.key.displayName(null), entry.value);
      });
    }

    test('every report type has a non-empty fallback label', () {
      for (final t in ReportType.values) {
        expect(
          t.displayName(null),
          isNotEmpty,
          reason: '$t returned empty fallback display name',
        );
      }
    });
  });

  group('enum invariants', () {
    test('enum has exactly 10 values', () {
      expect(ReportType.values.length, 10);
    });

    test(
        'needsPrice, needsText, and status bucket are mutually exclusive and '
        'together cover every enum value', () {
      for (final t in ReportType.values) {
        final isStatus =
            t == ReportType.wrongStatusOpen || t == ReportType.wrongStatusClosed;
        final bucketCount =
            (t.needsPrice ? 1 : 0) + (t.needsText ? 1 : 0) + (isStatus ? 1 : 0);
        expect(
          bucketCount,
          1,
          reason:
              '$t must belong to exactly one bucket (price/text/status); got $bucketCount',
        );
      }
    });
  });
}
