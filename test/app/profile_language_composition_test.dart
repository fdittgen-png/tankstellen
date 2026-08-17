// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/app/app_initializer.dart';
import 'package:tankstellen/core/language/profile_language_bridge.dart';
import 'package:tankstellen/features/profile/data/repositories/profile_repository.dart';
import 'package:tankstellen/features/profile/domain/entities/user_profile.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

class _FakeUserProfile extends Fake implements UserProfile {}

/// #3738 — composition-root regression test for the #3134 profile-language
/// bridge.
///
/// The bridge's two seams (`profileLanguageCodeProvider` /
/// `profileLanguageWriterProvider`) are implemented in
/// `lib/app/profile_language_binding.dart`, but for months NOTHING
/// installed them: `AppInitializer.run()` built a bare
/// `ProviderContainer()`, so the production app silently ran on the
/// unbound defaults (read → null, write → no-op) while every unit test —
/// installing its own overrides — stayed green.
///
/// These tests therefore build the container through the PRODUCTION
/// construction path ([AppInitializer.createContainer], the exact factory
/// `run()` uses) and assert both seams reflect the real profile feature.
/// If the overrides are ever dropped from the factory again, the reads
/// below fall back to the unbound defaults and this file goes red.
void main() {
  setUpAll(() {
    registerFallbackValue(_FakeUserProfile());
  });

  const activeProfile = UserProfile(
    id: 'p1',
    name: 'Test profile',
    languageCode: 'fr',
  );

  test(
      'production container wiring installs the read seam — '
      'profileLanguageCodeProvider reflects the active profile', () {
    final repo = _MockProfileRepository();
    when(repo.getActiveProfile).thenReturn(activeProfile);

    final container = AppInitializer.createContainer(overrides: [
      profileRepositoryProvider.overrideWith((ref) => repo),
    ]);
    addTearDown(container.dispose);

    // Unbound (dead-code #3738) this reads null; wired it reads 'fr'.
    expect(container.read(profileLanguageCodeProvider), 'fr');
  });

  test(
      'production container wiring installs the write seam — '
      'the writer persists the picked code onto the active profile',
      () async {
    final repo = _MockProfileRepository();
    when(repo.getActiveProfile).thenReturn(activeProfile);
    when(() => repo.updateProfile(any())).thenAnswer((_) async {});

    final container = AppInitializer.createContainer(overrides: [
      profileRepositoryProvider.overrideWith((ref) => repo),
    ]);
    addTearDown(container.dispose);

    // Unbound (dead-code #3738) the writer is a no-op; wired it writes
    // the picked code through the profile repository.
    await container.read(profileLanguageWriterProvider)('it');

    final written = verify(() => repo.updateProfile(captureAny()))
        .captured
        .single as UserProfile;
    expect(written.id, 'p1');
    expect(written.languageCode, 'it');
  });

  test('read seam stays reactive — a profile switch rebuilds the code', () {
    final repo = _MockProfileRepository();
    when(repo.getActiveProfile).thenReturn(activeProfile);

    final container = AppInitializer.createContainer(overrides: [
      profileRepositoryProvider.overrideWith((ref) => repo),
    ]);
    addTearDown(container.dispose);

    // Keep the keepAlive bridge provider observed so upstream changes
    // rebuild it (mirrors profile_language_bridge_test.dart).
    container.listen(profileLanguageCodeProvider, (previous, next) {});
    expect(container.read(profileLanguageCodeProvider), 'fr');

    when(repo.getActiveProfile).thenReturn(
      activeProfile.copyWith(languageCode: 'de'),
    );
    container.read(activeProfileProvider.notifier).refresh();

    expect(container.read(profileLanguageCodeProvider), 'de');
  });
}
