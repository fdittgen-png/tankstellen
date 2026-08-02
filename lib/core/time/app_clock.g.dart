// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_clock.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide clock. keepAlive — the clock has no state to dispose and
/// every layer may read it.

@ProviderFor(appClock)
final appClockProvider = AppClockProvider._();

/// App-wide clock. keepAlive — the clock has no state to dispose and
/// every layer may read it.

final class AppClockProvider
    extends $FunctionalProvider<AppClock, AppClock, AppClock>
    with $Provider<AppClock> {
  /// App-wide clock. keepAlive — the clock has no state to dispose and
  /// every layer may read it.
  AppClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appClockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appClockHash();

  @$internal
  @override
  $ProviderElement<AppClock> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppClock create(Ref ref) {
    return appClock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppClock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppClock>(value),
    );
  }
}

String _$appClockHash() => r'fbbe189ccb6cd6778b4b02cced63c518e6b55c93';
