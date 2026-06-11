// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/misc.dart';

import '../core/language/profile_language_bridge.dart';
import '../features/profile/providers/profile_provider.dart';

/// Composition-root binding of the profile-language bridge (#3134).
///
/// `core/language` must never import the profile feature (epic #3129),
/// so `ActiveLanguage` reads/writes the active profile's language through
/// the two seams in `lib/core/language/profile_language_bridge.dart`.
/// The app shell is the one layer allowed to see both sides, so the real
/// implementations are bound here and installed as container overrides
/// by [AppInitializer].
///
/// The read seam stays fully reactive: profile switches/edits rebuild
/// `activeLanguageProvider` exactly as the old direct
/// `activeProfileProvider` watch did.
List<Override> profileLanguageOverrides() => [
      profileLanguageCodeProvider.overrideWith(
        (ref) => ref.watch(activeProfileProvider)?.languageCode,
      ),
      profileLanguageWriterProvider.overrideWith(
        (ref) => (code) async {
          final profile = ref.read(activeProfileProvider);
          if (profile == null) return;
          // Capture before the await — Riverpod 3 forbids ref use after
          // an await once the element is disposed (#3159).
          final repo = ref.read(profileRepositoryProvider);
          final notifier = ref.read(activeProfileProvider.notifier);
          await repo.updateProfile(profile.copyWith(languageCode: code));
          notifier.refresh();
        },
      ),
    ];
