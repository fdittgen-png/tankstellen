// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/language/language_provider.dart';
import 'package:tankstellen/core/language/profile_language_bridge.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';

class _MockStorage extends Mock implements StorageRepository {}

/// Mutable language-code source standing in for the profile feature's
/// `activeProfileProvider` watch in the reactivity test below.
class _CodeSource extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? code) => state = code;
}

/// #3134 — `core/language` no longer imports the profile feature; the
/// profile-language coupling goes through the two bridge seams in
/// `profile_language_bridge.dart`. These tests lock the seam contract
/// that the old direct `activeProfileProvider` watch provided:
///
///   1. a bound profile language is the highest-priority source,
///   2. an unbound (null) / unknown bridge value falls through to the
///      persisted setting,
///   3. bridge changes (profile switch/edit) rebuild the language,
///   4. `select()` persists to storage AND pushes through the write seam.
void main() {
  late _MockStorage storage;

  setUp(() {
    storage = _MockStorage();
    when(() => storage.putSetting(any(), any<dynamic>()))
        .thenAnswer((_) async {});
  });

  ProviderContainer makeContainer(List<Override> overrides) {
    final container = ProviderContainer(overrides: [
      storageRepositoryProvider.overrideWithValue(storage),
      ...overrides,
    ]);
    addTearDown(container.dispose);
    return container;
  }

  test('bridge-bound profile language wins over the persisted setting', () {
    when(() => storage.getSetting('active_language_code')).thenReturn('de');
    final container = makeContainer([
      profileLanguageCodeProvider.overrideWith((ref) => 'fr'),
    ]);
    expect(container.read(activeLanguageProvider).code, 'fr');
  });

  test('unbound bridge (null) falls back to the persisted setting', () {
    when(() => storage.getSetting('active_language_code')).thenReturn('de');
    final container = makeContainer(const []);
    expect(container.read(activeLanguageProvider).code, 'de');
  });

  test('unknown bridge code falls back to the persisted setting', () {
    when(() => storage.getSetting('active_language_code')).thenReturn('de');
    final container = makeContainer([
      profileLanguageCodeProvider.overrideWith((ref) => 'xx'),
    ]);
    expect(container.read(activeLanguageProvider).code, 'de');
  });

  test('bridge changes rebuild the active language (profile switch)', () {
    when(() => storage.getSetting('active_language_code')).thenReturn('de');
    final source = NotifierProvider<_CodeSource, String?>(_CodeSource.new);
    final container = makeContainer([
      profileLanguageCodeProvider.overrideWith(
        (ref) => ref.watch(source),
      ),
    ]);
    // Keep the keepAlive provider observed so dependency changes rebuild it.
    container.listen(activeLanguageProvider, (previous, next) {});

    expect(container.read(activeLanguageProvider).code, 'de');
    container.read(source.notifier).set('it');
    expect(container.read(activeLanguageProvider).code, 'it');
  });

  test('select() persists the code and pushes it through the write seam',
      () async {
    when(() => storage.getSetting('active_language_code')).thenReturn(null);
    final written = <String>[];
    final container = makeContainer([
      profileLanguageWriterProvider.overrideWith(
        (ref) => (code) async => written.add(code),
      ),
    ]);

    final french = AppLanguages.byCode('fr')!;
    await container.read(activeLanguageProvider.notifier).select(french);

    verify(() => storage.putSetting('active_language_code', 'fr')).called(1);
    expect(written, ['fr']);
    expect(container.read(activeLanguageProvider).code, 'fr');
  });
}
