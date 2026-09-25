// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/data/repositories/profile_repository.dart';

void main() {
  late _Storage storage;
  late ProfileRepository repo;
  final loggedErrors = <Object>[];
  const source = UserProfile(id: 'source', name: 'France', countryCode: 'FR');
  CountryProfileProposal proposal(String country) => CountryProfileProposal(
    source: source,
    countryCode: country,
    fuel: FuelType.e10,
    name: country,
  );

  setUp(() {
    loggedErrors.clear();
    errorLogger.spoolEnqueueOverride =
        ({
          required isolateTaskName,
          required error,
          stack,
          contextMap,
          timestamp,
        }) async {
          loggedErrors.add(error);
        };
    storage = _Storage();
    repo = ProfileRepository(storage);
  });

  tearDown(errorLogger.resetForTest);

  test(
    'overlapping batches create one profile per normalized country',
    () async {
      final gate = Completer<void>();
      storage.gate = gate;
      final first = repo.createMissingCountryProfiles([proposal(' es ')]);
      await storage.writeStarted.future;
      final second = ProfileRepository(
        storage,
      ).createMissingCountryProfiles([proposal('ES')]);
      gate.complete();
      final results = await Future.wait([first, second]);
      expect(repo.getAllProfiles(), hasLength(1));
      expect(repo.getAllProfiles().single.countryCode, 'ES');
      expect(results.expand((r) => r.created), hasLength(1));
      expect(results.expand((r) => r.skipped), ['ES']);
      expect(storage.activeId, isNull);
    },
  );

  test(
    'batch does not undo an explicit country switch during persistence',
    () async {
      storage.rows['source'] = source.toJson();
      storage.rows['other'] = source
          .copyWith(id: 'other', countryCode: 'IT')
          .toJson();
      storage.activeId = 'source';
      final gate = Completer<void>();
      storage.gate = gate;
      final batch = repo.createMissingCountryProfiles([proposal('ES')]);
      await storage.writeStarted.future;
      await repo.setActiveProfile('other');
      gate.complete();
      await batch;
      expect(storage.activeId, 'other');
    },
  );

  test('legacy country casing is treated as configured', () async {
    storage.rows['legacy'] = source
        .copyWith(id: 'legacy', countryCode: ' es ')
        .toJson();
    final result = await repo.createMissingCountryProfiles([proposal('ES')]);
    expect(result.skipped, ['ES']);
    expect(result.created, isEmpty);
    expect(repo.getAllProfiles(), hasLength(1));
  });

  test('a failed country write permits a later retry', () async {
    storage.failNext = true;
    final failed = await repo.createMissingCountryProfiles([proposal('ES')]);
    expect(failed.failed.keys, ['ES']);
    expect(loggedErrors, hasLength(1));
    final retry = await repo.createMissingCountryProfiles([proposal('ES')]);
    expect(retry.isComplete, isTrue);
    expect(retry.created, hasLength(1));
  });
}

class _Storage extends HiveStorage {
  final rows = <String, Map<String, dynamic>>{};
  String? activeId;
  Completer<void>? gate;
  final writeStarted = Completer<void>();
  bool failNext = false;

  @override
  List<Map<String, dynamic>> getAllProfiles() => rows.values.toList();
  @override
  Map<String, dynamic>? getProfile(String id) => rows[id];
  @override
  String? getActiveProfileId() => activeId;
  @override
  Future<void> setActiveProfileId(String id) async => activeId = id;
  @override
  Future<void> saveProfile(String id, Map<String, dynamic> profile) async {
    if (!writeStarted.isCompleted) writeStarted.complete();
    if (gate != null) await gate!.future;
    if (failNext) {
      failNext = false;
      throw StateError('injected storage failure');
    }
    rows[id] = profile;
  }
}
