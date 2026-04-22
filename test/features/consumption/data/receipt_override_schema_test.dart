import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/receipt_override_registry.dart';

/// Validates the shipped override catalogue
/// (`assets/receipt_overrides/index.json`) against the JSON schema the
/// registry expects.
///
/// Phase 1 ships the catalogue empty — the test must pass against `{}`.
/// When operators start landing real overrides the same test also
/// enforces that every entry survives the registry parser (every regex
/// compiles, every group index is non-negative, every top-level key is
/// a non-empty string).
void main() {
  test('assets/receipt_overrides/index.json is valid schema (#759 phase 1)',
      () {
    const assetPath = 'assets/receipt_overrides/index.json';
    final file = File(assetPath);
    expect(
      file.existsSync(),
      isTrue,
      reason:
          'Asset $assetPath must exist (ship {} when the catalogue is empty).',
    );

    final raw = file.readAsStringSync();

    // Must be valid JSON.
    Object? decoded;
    try {
      decoded = json.decode(raw);
    } on FormatException catch (e) {
      fail('$assetPath is not valid JSON: $e');
    }

    // Must be a top-level object.
    expect(
      decoded,
      isA<Map<String, dynamic>>(),
      reason: 'Top-level must be an object mapping stationId → overrideSpec.',
    );

    final map = decoded! as Map<String, dynamic>;

    // Every entry must round-trip through the registry parser without
    // being dropped. If the registry parses `N` entries for us from
    // this file, the catalogue has `N` stationIds — no silent losses.
    final registry = ReceiptOverrideRegistry.fromJsonString(raw);

    // Count entries that *survive* validation in the real loader — empty
    // specs are treated as "no override" which is legal but weird; keys
    // with at least one populated field must survive intact.
    var expectedActiveEntries = 0;
    for (final entry in map.entries) {
      expect(
        entry.key,
        isA<String>(),
        reason: 'Every top-level key must be a string stationId.',
      );
      expect(
        entry.key.isNotEmpty,
        isTrue,
        reason: 'stationId keys must be non-empty.',
      );
      final spec = OverrideSpec.fromJson(entry.value);
      expect(
        spec,
        isNotNull,
        reason:
            'Entry for ${entry.key} failed schema validation — check field '
            'shapes (pattern: String, group: int).',
      );
      if (!spec!.isEmpty) expectedActiveEntries++;
    }

    // Every stationId that the schema validator accepted must also be
    // present in the registry's cache. If the counts diverge a field
    // validation slipped through the cracks.
    expect(registry.entryCount, expectedActiveEntries);
  });
}
