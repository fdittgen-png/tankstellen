// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'language_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ActiveLanguage)
final activeLanguageProvider = ActiveLanguageProvider._();

final class ActiveLanguageProvider
    extends $NotifierProvider<ActiveLanguage, AppLanguage> {
  ActiveLanguageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeLanguageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeLanguageHash();

  @$internal
  @override
  ActiveLanguage create() => ActiveLanguage();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppLanguage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppLanguage>(value),
    );
  }
}

String _$activeLanguageHash() => r'628516e56d2716c31c8c6d8e00f2b7b9e944d9f9';

abstract class _$ActiveLanguage extends $Notifier<AppLanguage> {
  AppLanguage build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AppLanguage, AppLanguage>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppLanguage, AppLanguage>,
              AppLanguage,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
