// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'fill_inventory_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The inventory the most recent fill established (#3917), persisted in
/// the settings box so the Carburant tab keeps showing it across
/// restarts until the next fill replaces it.
///
/// The fill-up save path publishes it through [set]; the post-save
/// sheet and the [FillInventoryCard] read it. Never throws on a
/// malformed stored payload — a stale setting reads as "no inventory".

@ProviderFor(LastFillInventory)
final lastFillInventoryProvider = LastFillInventoryProvider._();

/// The inventory the most recent fill established (#3917), persisted in
/// the settings box so the Carburant tab keeps showing it across
/// restarts until the next fill replaces it.
///
/// The fill-up save path publishes it through [set]; the post-save
/// sheet and the [FillInventoryCard] read it. Never throws on a
/// malformed stored payload — a stale setting reads as "no inventory".
final class LastFillInventoryProvider
    extends $NotifierProvider<LastFillInventory, FillInventory?> {
  /// The inventory the most recent fill established (#3917), persisted in
  /// the settings box so the Carburant tab keeps showing it across
  /// restarts until the next fill replaces it.
  ///
  /// The fill-up save path publishes it through [set]; the post-save
  /// sheet and the [FillInventoryCard] read it. Never throws on a
  /// malformed stored payload — a stale setting reads as "no inventory".
  LastFillInventoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lastFillInventoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lastFillInventoryHash();

  @$internal
  @override
  LastFillInventory create() => LastFillInventory();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FillInventory? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FillInventory?>(value),
    );
  }
}

String _$lastFillInventoryHash() => r'8407c3839a08ff6cfa9de81553bd2ab06f589d07';

/// The inventory the most recent fill established (#3917), persisted in
/// the settings box so the Carburant tab keeps showing it across
/// restarts until the next fill replaces it.
///
/// The fill-up save path publishes it through [set]; the post-save
/// sheet and the [FillInventoryCard] read it. Never throws on a
/// malformed stored payload — a stale setting reads as "no inventory".

abstract class _$LastFillInventory extends $Notifier<FillInventory?> {
  FillInventory? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<FillInventory?, FillInventory?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FillInventory?, FillInventory?>,
              FillInventory?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
