// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unified_filter_chips.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod state holder for the active [UnifiedFilter]. Non-keep-alive
/// because the chip selection is screen-scoped: leaving the search
/// results screen and coming back resets to [UnifiedFilter.both], which
/// matches the expectation that filters are session-local.

@ProviderFor(UnifiedFilterState)
final unifiedFilterStateProvider = UnifiedFilterStateProvider._();

/// Riverpod state holder for the active [UnifiedFilter]. Non-keep-alive
/// because the chip selection is screen-scoped: leaving the search
/// results screen and coming back resets to [UnifiedFilter.both], which
/// matches the expectation that filters are session-local.
final class UnifiedFilterStateProvider
    extends $NotifierProvider<UnifiedFilterState, UnifiedFilter> {
  /// Riverpod state holder for the active [UnifiedFilter]. Non-keep-alive
  /// because the chip selection is screen-scoped: leaving the search
  /// results screen and coming back resets to [UnifiedFilter.both], which
  /// matches the expectation that filters are session-local.
  UnifiedFilterStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unifiedFilterStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unifiedFilterStateHash();

  @$internal
  @override
  UnifiedFilterState create() => UnifiedFilterState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UnifiedFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UnifiedFilter>(value),
    );
  }
}

String _$unifiedFilterStateHash() =>
    r'af44dbcd3fca865bdacc1862d2e93ca6908e4b37';

/// Riverpod state holder for the active [UnifiedFilter]. Non-keep-alive
/// because the chip selection is screen-scoped: leaving the search
/// results screen and coming back resets to [UnifiedFilter.both], which
/// matches the expectation that filters are session-local.

abstract class _$UnifiedFilterState extends $Notifier<UnifiedFilter> {
  UnifiedFilter build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<UnifiedFilter, UnifiedFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UnifiedFilter, UnifiedFilter>,
              UnifiedFilter,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
