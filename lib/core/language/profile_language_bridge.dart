// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_language_bridge.g.dart';

/// Applies a user-picked language code to the active profile.
typedef ProfileLanguageWriter = Future<void> Function(String code);

/// Read seam of the profile-language bridge (#3134).
///
/// `core/language` must not import the profile feature (epic #3129:
/// core never depends on `lib/features/`), but the active profile's
/// `languageCode` is the highest-priority language source. This provider
/// is core's view of that value; the **composition root**
/// (`AppInitializer` — the app shell may depend on both sides) overrides
/// it with a reactive read of the profile feature's
/// `activeProfileProvider`.
///
/// The unbound default is `null` ("no profile system present"), which
/// makes `ActiveLanguage` fall through to the persisted setting / system
/// locale — the exact behavior of a fresh install without profiles.
@Riverpod(keepAlive: true)
String? profileLanguageCode(Ref ref) => null;

/// Write seam of the profile-language bridge (#3134).
///
/// `ActiveLanguage.select` persists the picked language into the active
/// profile. The implementation lives behind this provider so core never
/// imports the profile feature; the composition root overrides it with
/// the real profile write. The unbound default is a no-op (no profile
/// system present — e.g. unit tests).
@Riverpod(keepAlive: true)
ProfileLanguageWriter profileLanguageWriter(Ref ref) => (_) async {};
