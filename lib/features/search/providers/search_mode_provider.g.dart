// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_mode_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ActiveSearchMode)
final activeSearchModeProvider = ActiveSearchModeProvider._();

final class ActiveSearchModeProvider
    extends $NotifierProvider<ActiveSearchMode, SearchMode> {
  ActiveSearchModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeSearchModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeSearchModeHash();

  @$internal
  @override
  ActiveSearchMode create() => ActiveSearchMode();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchMode>(value),
    );
  }
}

String _$activeSearchModeHash() => r'e9d945a2e5bd48872de6cc0566a0001a99942c57';

abstract class _$ActiveSearchMode extends $Notifier<SearchMode> {
  SearchMode build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SearchMode, SearchMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SearchMode, SearchMode>,
              SearchMode,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
