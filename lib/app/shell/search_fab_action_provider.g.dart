// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_fab_action_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SearchFabActionController)
final searchFabActionControllerProvider = SearchFabActionControllerProvider._();

final class SearchFabActionControllerProvider
    extends $NotifierProvider<SearchFabActionController, SearchFabAction?> {
  SearchFabActionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchFabActionControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchFabActionControllerHash();

  @$internal
  @override
  SearchFabActionController create() => SearchFabActionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchFabAction? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchFabAction?>(value),
    );
  }
}

String _$searchFabActionControllerHash() =>
    r'2138e732c10b57351810fa2d7053f3d25033c21e';

abstract class _$SearchFabActionController extends $Notifier<SearchFabAction?> {
  SearchFabAction? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SearchFabAction?, SearchFabAction?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SearchFabAction?, SearchFabAction?>,
              SearchFabAction?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
