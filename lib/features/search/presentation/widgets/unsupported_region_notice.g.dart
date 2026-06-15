// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unsupported_region_notice.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// #3361 — session dismissal of the location-coverage notice. Resets each app
/// launch (a light touch — the gap is worth re-surfacing once per session, not
/// nagging every rebuild). Kept out of storage on purpose.

@ProviderFor(UnsupportedRegionDismissed)
final unsupportedRegionDismissedProvider =
    UnsupportedRegionDismissedProvider._();

/// #3361 — session dismissal of the location-coverage notice. Resets each app
/// launch (a light touch — the gap is worth re-surfacing once per session, not
/// nagging every rebuild). Kept out of storage on purpose.
final class UnsupportedRegionDismissedProvider
    extends $NotifierProvider<UnsupportedRegionDismissed, bool> {
  /// #3361 — session dismissal of the location-coverage notice. Resets each app
  /// launch (a light touch — the gap is worth re-surfacing once per session, not
  /// nagging every rebuild). Kept out of storage on purpose.
  UnsupportedRegionDismissedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unsupportedRegionDismissedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unsupportedRegionDismissedHash();

  @$internal
  @override
  UnsupportedRegionDismissed create() => UnsupportedRegionDismissed();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$unsupportedRegionDismissedHash() =>
    r'cccbd2994dc70bf92f19a6a04fb24226374f688d';

/// #3361 — session dismissal of the location-coverage notice. Resets each app
/// launch (a light touch — the gap is worth re-surfacing once per session, not
/// nagging every rebuild). Kept out of storage on purpose.

abstract class _$UnsupportedRegionDismissed extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
