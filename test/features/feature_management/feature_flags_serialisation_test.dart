// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4225 — "concurrent changes cannot leave partial activation".
//
// Every mutation is read-modify-persist. Before the fix, two toggles
// started before either persisted both read the SAME resolved set, so
// the second write dropped the first one's change. A lost update is
// invisible: the UI shows what the last writer thought, and the user's
// other toggle silently never happened.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/data/feature_flags_repository.dart';
import 'package:tankstellen/features/feature_management/domain/build_channel.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';

/// A repository whose writes take a turn of the event loop — the shape
/// a real Hive write has, and the window the race needed.
///
/// `FeatureFlagsRepository` is a concrete Hive wrapper rather than an
/// interface, so `implements` has to satisfy `isEmpty` as well.
class _SlowRepo implements FeatureFlagsRepository {
  _SlowRepo(this._stored);

  Set<Feature> _stored;
  int writes = 0;

  @override
  bool get isEmpty => _stored.isEmpty;

  @override
  Future<Set<Feature>> loadEnabled([
    BuildChannel channel = BuildChannel.production,
  ]) async {
    await Future<void>.delayed(Duration.zero);
    return {..._stored};
  }

  @override
  Future<void> saveEnabled(Set<Feature> enabled) async {
    await Future<void>.delayed(Duration.zero);
    writes++;
    _stored = {...enabled};
  }
}

void main() {
  late _SlowRepo repo;
  late ProviderContainer container;

  setUp(() {
    // Start from a set that satisfies prerequisites, so enabling a
    // dependent is legal and the test is about ordering, not guards.
    repo = _SlowRepo({Feature.obd2TripRecording});
    container = ProviderContainer(overrides: [
      featureFlagsRepositoryProvider.overrideWithValue(repo),
      buildChannelProvider.overrideWithValue(BuildChannel.production),
    ]);
  });

  tearDown(() => container.dispose());

  test('two enables started together BOTH land (no lost update)', () async {
    final flags = container.read(featureFlagsProvider.notifier);
    await container.read(featureFlagsProvider.future);

    // Fire both before either persists — the race window.
    await Future.wait([
      flags.enable(Feature.hapticEcoCoach),
      flags.enable(Feature.glideCoach),
    ]);

    final result = await container.read(featureFlagsProvider.future);
    expect(result, contains(Feature.hapticEcoCoach));
    expect(result, contains(Feature.glideCoach),
        reason: 'the second mutation must read the first one\'s result, '
            'not the set from before it');
    expect(repo.writes, 2, reason: 'both writes reached storage');
  });

  test('an enable and a disable started together do not cancel out',
      () async {
    final flags = container.read(featureFlagsProvider.notifier);
    await container.read(featureFlagsProvider.future);
    await flags.enable(Feature.hapticEcoCoach);

    await Future.wait([
      flags.enable(Feature.glideCoach),
      flags.disable(Feature.hapticEcoCoach),
    ]);

    final result = await container.read(featureFlagsProvider.future);
    expect(result, contains(Feature.glideCoach));
    expect(result, isNot(contains(Feature.hapticEcoCoach)));
  });

  test('a failed mutation does not poison the queue', () async {
    final flags = container.read(featureFlagsProvider.notifier);
    await container.read(featureFlagsProvider.future);

    // voiceAnnouncements requires approachOverlay + voiceFeedback, so
    // this one throws — and the NEXT mutation must still run.
    await expectLater(
      flags.enable(Feature.voiceAnnouncements),
      throwsStateError,
    );
    await flags.enable(Feature.hapticEcoCoach);

    expect(await container.read(featureFlagsProvider.future),
        contains(Feature.hapticEcoCoach));
  });
}
