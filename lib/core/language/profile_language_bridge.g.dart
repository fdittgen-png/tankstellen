// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_language_bridge.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(profileLanguageCode)
final profileLanguageCodeProvider = ProfileLanguageCodeProvider._();

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

final class ProfileLanguageCodeProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
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
  ProfileLanguageCodeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileLanguageCodeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileLanguageCodeHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return profileLanguageCode(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$profileLanguageCodeHash() =>
    r'aa7b008d679266c357b704438bd46cfd951387b1';

/// Write seam of the profile-language bridge (#3134).
///
/// `ActiveLanguage.select` persists the picked language into the active
/// profile. The implementation lives behind this provider so core never
/// imports the profile feature; the composition root overrides it with
/// the real profile write. The unbound default is a no-op (no profile
/// system present — e.g. unit tests).

@ProviderFor(profileLanguageWriter)
final profileLanguageWriterProvider = ProfileLanguageWriterProvider._();

/// Write seam of the profile-language bridge (#3134).
///
/// `ActiveLanguage.select` persists the picked language into the active
/// profile. The implementation lives behind this provider so core never
/// imports the profile feature; the composition root overrides it with
/// the real profile write. The unbound default is a no-op (no profile
/// system present — e.g. unit tests).

final class ProfileLanguageWriterProvider
    extends
        $FunctionalProvider<
          ProfileLanguageWriter,
          ProfileLanguageWriter,
          ProfileLanguageWriter
        >
    with $Provider<ProfileLanguageWriter> {
  /// Write seam of the profile-language bridge (#3134).
  ///
  /// `ActiveLanguage.select` persists the picked language into the active
  /// profile. The implementation lives behind this provider so core never
  /// imports the profile feature; the composition root overrides it with
  /// the real profile write. The unbound default is a no-op (no profile
  /// system present — e.g. unit tests).
  ProfileLanguageWriterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileLanguageWriterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileLanguageWriterHash();

  @$internal
  @override
  $ProviderElement<ProfileLanguageWriter> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProfileLanguageWriter create(Ref ref) {
    return profileLanguageWriter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileLanguageWriter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileLanguageWriter>(value),
    );
  }
}

String _$profileLanguageWriterHash() =>
    r'13799cd804eddaa531cb286f6aac0e2d6115c8b1';
