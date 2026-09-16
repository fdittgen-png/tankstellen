// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'usual_station_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The confirmed usual station (#4154) — null until the user sets one.

@ProviderFor(UsualStationSetting)
final usualStationSettingProvider = UsualStationSettingProvider._();

/// The confirmed usual station (#4154) — null until the user sets one.
final class UsualStationSettingProvider
    extends $NotifierProvider<UsualStationSetting, UsualStation?> {
  /// The confirmed usual station (#4154) — null until the user sets one.
  UsualStationSettingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'usualStationSettingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$usualStationSettingHash();

  @$internal
  @override
  UsualStationSetting create() => UsualStationSetting();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UsualStation? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UsualStation?>(value),
    );
  }
}

String _$usualStationSettingHash() =>
    r'ed9866bf8dcad61945681aba38c33d78fb4ae527';

/// The confirmed usual station (#4154) — null until the user sets one.

abstract class _$UsualStationSetting extends $Notifier<UsualStation?> {
  UsualStation? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<UsualStation?, UsualStation?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UsualStation?, UsualStation?>,
              UsualStation?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// What the fill-up history suggests, or null when it is too thin (#4154).
///
/// Offered, never applied: [UsualStationSetting] only changes on an
/// explicit confirm. A wrong "usual" makes every finding about it wrong,
/// and the ranking cannot tell a habit from a fortnight of holiday
/// driving — so the user is the one who decides.
///
/// The `fill_ups` dependency goes through that feature's `api.dart`
/// barrel, which `feature_boundary_test` exempts from its per-pair
/// count; reaching into `providers/` directly would be the violation.

@ProviderFor(usualStationSuggestion)
final usualStationSuggestionProvider = UsualStationSuggestionProvider._();

/// What the fill-up history suggests, or null when it is too thin (#4154).
///
/// Offered, never applied: [UsualStationSetting] only changes on an
/// explicit confirm. A wrong "usual" makes every finding about it wrong,
/// and the ranking cannot tell a habit from a fortnight of holiday
/// driving — so the user is the one who decides.
///
/// The `fill_ups` dependency goes through that feature's `api.dart`
/// barrel, which `feature_boundary_test` exempts from its per-pair
/// count; reaching into `providers/` directly would be the violation.

final class UsualStationSuggestionProvider
    extends
        $FunctionalProvider<
          UsualStationCandidate?,
          UsualStationCandidate?,
          UsualStationCandidate?
        >
    with $Provider<UsualStationCandidate?> {
  /// What the fill-up history suggests, or null when it is too thin (#4154).
  ///
  /// Offered, never applied: [UsualStationSetting] only changes on an
  /// explicit confirm. A wrong "usual" makes every finding about it wrong,
  /// and the ranking cannot tell a habit from a fortnight of holiday
  /// driving — so the user is the one who decides.
  ///
  /// The `fill_ups` dependency goes through that feature's `api.dart`
  /// barrel, which `feature_boundary_test` exempts from its per-pair
  /// count; reaching into `providers/` directly would be the violation.
  UsualStationSuggestionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'usualStationSuggestionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$usualStationSuggestionHash();

  @$internal
  @override
  $ProviderElement<UsualStationCandidate?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UsualStationCandidate? create(Ref ref) {
    return usualStationSuggestion(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UsualStationCandidate? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UsualStationCandidate?>(value),
    );
  }
}

String _$usualStationSuggestionHash() =>
    r'f1d23e7629953578f04b0517a341e3d375bbb85a';
