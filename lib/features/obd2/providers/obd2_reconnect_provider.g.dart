// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'obd2_reconnect_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Local (NON-synced) auto-pin store for the last-good adapter (#3019 /
/// Epic #3013 phase 3), backed by the Hive `settings` box.

@ProviderFor(lastGoodAdapterStore)
final lastGoodAdapterStoreProvider = LastGoodAdapterStoreProvider._();

/// Local (NON-synced) auto-pin store for the last-good adapter (#3019 /
/// Epic #3013 phase 3), backed by the Hive `settings` box.

final class LastGoodAdapterStoreProvider
    extends
        $FunctionalProvider<
          LastGoodAdapterStore,
          LastGoodAdapterStore,
          LastGoodAdapterStore
        >
    with $Provider<LastGoodAdapterStore> {
  /// Local (NON-synced) auto-pin store for the last-good adapter (#3019 /
  /// Epic #3013 phase 3), backed by the Hive `settings` box.
  LastGoodAdapterStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lastGoodAdapterStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lastGoodAdapterStoreHash();

  @$internal
  @override
  $ProviderElement<LastGoodAdapterStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LastGoodAdapterStore create(Ref ref) {
    return lastGoodAdapterStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LastGoodAdapterStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LastGoodAdapterStore>(value),
    );
  }
}

String _$lastGoodAdapterStoreHash() =>
    r'e3f12c50ac74faa882a1a248c7f6b1b80d74a623';

/// App-wide owner of THE [Obd2LinkSupervisor] (#3529, Epic #3527).
///
/// The supervisor is the single reconnect authority of the rewritten
/// link layer — this provider wires it into the app graph:
///   * the DEFAULT dial policy (auto-pinned adapter direct-connect
///     first, transport-correct, #3016; then a re-scan fallback);
///   * engine-off classification (#3035): a dial that reaches the
///     adapter but finds a silent bus parks the supervisor in
///     [Obd2LinkState.engineOff] instead of feeding the backoff loop;
///   * republishing a recovered link into the app-wide status dot;
///   * the #3346 episode breadcrumbs + gated comm-diagnostics counters.
///
/// Replaces the #3019 [Obd2ReconnectController] + arbiter idle-policy +
/// wedge-recovery constellation (deletion tracked by #3533): there is
/// no terminal-failed dead end anymore — the loop retries (capped
/// backoff) until the user disconnects or the engine is off.

@ProviderFor(Obd2Reconnect)
final obd2ReconnectProvider = Obd2ReconnectProvider._();

/// App-wide owner of THE [Obd2LinkSupervisor] (#3529, Epic #3527).
///
/// The supervisor is the single reconnect authority of the rewritten
/// link layer — this provider wires it into the app graph:
///   * the DEFAULT dial policy (auto-pinned adapter direct-connect
///     first, transport-correct, #3016; then a re-scan fallback);
///   * engine-off classification (#3035): a dial that reaches the
///     adapter but finds a silent bus parks the supervisor in
///     [Obd2LinkState.engineOff] instead of feeding the backoff loop;
///   * republishing a recovered link into the app-wide status dot;
///   * the #3346 episode breadcrumbs + gated comm-diagnostics counters.
///
/// Replaces the #3019 [Obd2ReconnectController] + arbiter idle-policy +
/// wedge-recovery constellation (deletion tracked by #3533): there is
/// no terminal-failed dead end anymore — the loop retries (capped
/// backoff) until the user disconnects or the engine is off.
final class Obd2ReconnectProvider
    extends $NotifierProvider<Obd2Reconnect, Obd2LinkState> {
  /// App-wide owner of THE [Obd2LinkSupervisor] (#3529, Epic #3527).
  ///
  /// The supervisor is the single reconnect authority of the rewritten
  /// link layer — this provider wires it into the app graph:
  ///   * the DEFAULT dial policy (auto-pinned adapter direct-connect
  ///     first, transport-correct, #3016; then a re-scan fallback);
  ///   * engine-off classification (#3035): a dial that reaches the
  ///     adapter but finds a silent bus parks the supervisor in
  ///     [Obd2LinkState.engineOff] instead of feeding the backoff loop;
  ///   * republishing a recovered link into the app-wide status dot;
  ///   * the #3346 episode breadcrumbs + gated comm-diagnostics counters.
  ///
  /// Replaces the #3019 [Obd2ReconnectController] + arbiter idle-policy +
  /// wedge-recovery constellation (deletion tracked by #3533): there is
  /// no terminal-failed dead end anymore — the loop retries (capped
  /// backoff) until the user disconnects or the engine is off.
  Obd2ReconnectProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'obd2ReconnectProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$obd2ReconnectHash();

  @$internal
  @override
  Obd2Reconnect create() => Obd2Reconnect();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Obd2LinkState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Obd2LinkState>(value),
    );
  }
}

String _$obd2ReconnectHash() => r'8814bbe7420381c3dda7dc57da5f995065c9e8bb';

/// App-wide owner of THE [Obd2LinkSupervisor] (#3529, Epic #3527).
///
/// The supervisor is the single reconnect authority of the rewritten
/// link layer — this provider wires it into the app graph:
///   * the DEFAULT dial policy (auto-pinned adapter direct-connect
///     first, transport-correct, #3016; then a re-scan fallback);
///   * engine-off classification (#3035): a dial that reaches the
///     adapter but finds a silent bus parks the supervisor in
///     [Obd2LinkState.engineOff] instead of feeding the backoff loop;
///   * republishing a recovered link into the app-wide status dot;
///   * the #3346 episode breadcrumbs + gated comm-diagnostics counters.
///
/// Replaces the #3019 [Obd2ReconnectController] + arbiter idle-policy +
/// wedge-recovery constellation (deletion tracked by #3533): there is
/// no terminal-failed dead end anymore — the loop retries (capped
/// backoff) until the user disconnects or the engine is off.

abstract class _$Obd2Reconnect extends $Notifier<Obd2LinkState> {
  Obd2LinkState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Obd2LinkState, Obd2LinkState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Obd2LinkState, Obd2LinkState>,
              Obd2LinkState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
