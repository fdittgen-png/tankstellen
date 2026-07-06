// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auto_record_orchestrator_factories.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Default factory: Android's foreground-service bridge, iOS's Core
/// Bluetooth state-restoration listener (#3167), an unimplemented stub
/// elsewhere. Tests override this provider to inject a
/// [FakeBackgroundAdapterListener] without touching platform-detection
/// code.

@ProviderFor(autoRecordListenerFactory)
final autoRecordListenerFactoryProvider = AutoRecordListenerFactoryProvider._();

/// Default factory: Android's foreground-service bridge, iOS's Core
/// Bluetooth state-restoration listener (#3167), an unimplemented stub
/// elsewhere. Tests override this provider to inject a
/// [FakeBackgroundAdapterListener] without touching platform-detection
/// code.

final class AutoRecordListenerFactoryProvider
    extends
        $FunctionalProvider<
          BackgroundAdapterListenerFactory,
          BackgroundAdapterListenerFactory,
          BackgroundAdapterListenerFactory
        >
    with $Provider<BackgroundAdapterListenerFactory> {
  /// Default factory: Android's foreground-service bridge, iOS's Core
  /// Bluetooth state-restoration listener (#3167), an unimplemented stub
  /// elsewhere. Tests override this provider to inject a
  /// [FakeBackgroundAdapterListener] without touching platform-detection
  /// code.
  AutoRecordListenerFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoRecordListenerFactoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoRecordListenerFactoryHash();

  @$internal
  @override
  $ProviderElement<BackgroundAdapterListenerFactory> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BackgroundAdapterListenerFactory create(Ref ref) {
    return autoRecordListenerFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackgroundAdapterListenerFactory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackgroundAdapterListenerFactory>(
        value,
      ),
    );
  }
}

String _$autoRecordListenerFactoryHash() =>
    r'c765df8cd84dd3bf14c78e048f7ded53fb72fcc3';

/// Default opener: opens a fresh [Obd2Service] for the configured MAC
/// via [Obd2ConnectionService.connectByMac] (#1004 phase 2b-3).
/// Returns null when the adapter is out of range or the scan times
/// out — the coordinator stays idle for that connect cycle and waits
/// for the next `AdapterConnected`. Tests override this provider to
/// inject a fake opener that returns a stub service.
///
/// #3167 — wrapped in [wrapStateRestorationOrigin] so the FIRST
/// auto-record connect after a Core Bluetooth background relaunch is
/// trace-stamped `Obd2ConnectOrigin.stateRestoration`. A no-op on a
/// normal launch and on Android (the tag is never set there).

@ProviderFor(autoRecordSessionOpenerFactory)
final autoRecordSessionOpenerFactoryProvider =
    AutoRecordSessionOpenerFactoryProvider._();

/// Default opener: opens a fresh [Obd2Service] for the configured MAC
/// via [Obd2ConnectionService.connectByMac] (#1004 phase 2b-3).
/// Returns null when the adapter is out of range or the scan times
/// out — the coordinator stays idle for that connect cycle and waits
/// for the next `AdapterConnected`. Tests override this provider to
/// inject a fake opener that returns a stub service.
///
/// #3167 — wrapped in [wrapStateRestorationOrigin] so the FIRST
/// auto-record connect after a Core Bluetooth background relaunch is
/// trace-stamped `Obd2ConnectOrigin.stateRestoration`. A no-op on a
/// normal launch and on Android (the tag is never set there).

final class AutoRecordSessionOpenerFactoryProvider
    extends
        $FunctionalProvider<
          Obd2SessionOpener,
          Obd2SessionOpener,
          Obd2SessionOpener
        >
    with $Provider<Obd2SessionOpener> {
  /// Default opener: opens a fresh [Obd2Service] for the configured MAC
  /// via [Obd2ConnectionService.connectByMac] (#1004 phase 2b-3).
  /// Returns null when the adapter is out of range or the scan times
  /// out — the coordinator stays idle for that connect cycle and waits
  /// for the next `AdapterConnected`. Tests override this provider to
  /// inject a fake opener that returns a stub service.
  ///
  /// #3167 — wrapped in [wrapStateRestorationOrigin] so the FIRST
  /// auto-record connect after a Core Bluetooth background relaunch is
  /// trace-stamped `Obd2ConnectOrigin.stateRestoration`. A no-op on a
  /// normal launch and on Android (the tag is never set there).
  AutoRecordSessionOpenerFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoRecordSessionOpenerFactoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoRecordSessionOpenerFactoryHash();

  @$internal
  @override
  $ProviderElement<Obd2SessionOpener> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Obd2SessionOpener create(Ref ref) {
    return autoRecordSessionOpenerFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Obd2SessionOpener value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Obd2SessionOpener>(value),
    );
  }
}

String _$autoRecordSessionOpenerFactoryHash() =>
    r'79e2b0443759a4b43c80c4d32129b2a4d18e7272';

/// Foreground-active opener (#2282 concern 1): a DIRECT connect — NO active
/// scan — so it wakes ELM327 clones that stop advertising in standby. Used by
/// the coordinator's [AutoTripCoordinator.armForegroundActive] on every app
/// resume to start engine-detection while the app is in front, independent of
/// the disabled foreground service.
///
/// #3025 — now TRANSPORT-AWARE via
/// [Obd2ConnectionService.connectByMacTransportAware]. The old call hard-wired
/// the BLE [Obd2ConnectionService.connectByMacDirect], so a Classic-SPP adapter
/// (vLinker BM-Android) could only 4 s-timeout AND the doomed BLE GATT to its
/// MAC poisoned the RFCOMM socket — the same firstConnect defect this opener
/// shared. Transport is inferred from the paired adapter NAME (read defensively
/// off the active vehicle so a provider hiccup never makes the connect throw).
/// `fallbackToScan: true` keeps behaviour no worse than the scan opener when the
/// direct attempt fails. Tests override this provider to inject a fake opener.

@ProviderFor(autoRecordForegroundSessionOpenerFactory)
final autoRecordForegroundSessionOpenerFactoryProvider =
    AutoRecordForegroundSessionOpenerFactoryProvider._();

/// Foreground-active opener (#2282 concern 1): a DIRECT connect — NO active
/// scan — so it wakes ELM327 clones that stop advertising in standby. Used by
/// the coordinator's [AutoTripCoordinator.armForegroundActive] on every app
/// resume to start engine-detection while the app is in front, independent of
/// the disabled foreground service.
///
/// #3025 — now TRANSPORT-AWARE via
/// [Obd2ConnectionService.connectByMacTransportAware]. The old call hard-wired
/// the BLE [Obd2ConnectionService.connectByMacDirect], so a Classic-SPP adapter
/// (vLinker BM-Android) could only 4 s-timeout AND the doomed BLE GATT to its
/// MAC poisoned the RFCOMM socket — the same firstConnect defect this opener
/// shared. Transport is inferred from the paired adapter NAME (read defensively
/// off the active vehicle so a provider hiccup never makes the connect throw).
/// `fallbackToScan: true` keeps behaviour no worse than the scan opener when the
/// direct attempt fails. Tests override this provider to inject a fake opener.

final class AutoRecordForegroundSessionOpenerFactoryProvider
    extends
        $FunctionalProvider<
          Obd2ForegroundSessionOpener,
          Obd2ForegroundSessionOpener,
          Obd2ForegroundSessionOpener
        >
    with $Provider<Obd2ForegroundSessionOpener> {
  /// Foreground-active opener (#2282 concern 1): a DIRECT connect — NO active
  /// scan — so it wakes ELM327 clones that stop advertising in standby. Used by
  /// the coordinator's [AutoTripCoordinator.armForegroundActive] on every app
  /// resume to start engine-detection while the app is in front, independent of
  /// the disabled foreground service.
  ///
  /// #3025 — now TRANSPORT-AWARE via
  /// [Obd2ConnectionService.connectByMacTransportAware]. The old call hard-wired
  /// the BLE [Obd2ConnectionService.connectByMacDirect], so a Classic-SPP adapter
  /// (vLinker BM-Android) could only 4 s-timeout AND the doomed BLE GATT to its
  /// MAC poisoned the RFCOMM socket — the same firstConnect defect this opener
  /// shared. Transport is inferred from the paired adapter NAME (read defensively
  /// off the active vehicle so a provider hiccup never makes the connect throw).
  /// `fallbackToScan: true` keeps behaviour no worse than the scan opener when the
  /// direct attempt fails. Tests override this provider to inject a fake opener.
  AutoRecordForegroundSessionOpenerFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoRecordForegroundSessionOpenerFactoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$autoRecordForegroundSessionOpenerFactoryHash();

  @$internal
  @override
  $ProviderElement<Obd2ForegroundSessionOpener> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Obd2ForegroundSessionOpener create(Ref ref) {
    return autoRecordForegroundSessionOpenerFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Obd2ForegroundSessionOpener value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Obd2ForegroundSessionOpener>(value),
    );
  }
}

String _$autoRecordForegroundSessionOpenerFactoryHash() =>
    r'2767dfb1262c9bd41e561d1fef3210daa04a3362';
