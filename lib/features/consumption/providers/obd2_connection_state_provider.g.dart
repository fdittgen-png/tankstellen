// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'obd2_connection_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide owner of the OBD2 connection status (#784).
///
/// Phase-1 scope: state machine + API for callers (boot probe,
/// manual disconnect, permission changes) to drive it. The actual
/// boot-time Bluetooth scan + auto-connect isolate is deferred to
/// the follow-up PR so this lands without coupling to the native
/// plugin surface.

@ProviderFor(Obd2ConnectionStatus)
final obd2ConnectionStatusProvider = Obd2ConnectionStatusProvider._();

/// App-wide owner of the OBD2 connection status (#784).
///
/// Phase-1 scope: state machine + API for callers (boot probe,
/// manual disconnect, permission changes) to drive it. The actual
/// boot-time Bluetooth scan + auto-connect isolate is deferred to
/// the follow-up PR so this lands without coupling to the native
/// plugin surface.
final class Obd2ConnectionStatusProvider
    extends $NotifierProvider<Obd2ConnectionStatus, Obd2ConnectionSnapshot> {
  /// App-wide owner of the OBD2 connection status (#784).
  ///
  /// Phase-1 scope: state machine + API for callers (boot probe,
  /// manual disconnect, permission changes) to drive it. The actual
  /// boot-time Bluetooth scan + auto-connect isolate is deferred to
  /// the follow-up PR so this lands without coupling to the native
  /// plugin surface.
  Obd2ConnectionStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'obd2ConnectionStatusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$obd2ConnectionStatusHash();

  @$internal
  @override
  Obd2ConnectionStatus create() => Obd2ConnectionStatus();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Obd2ConnectionSnapshot value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Obd2ConnectionSnapshot>(value),
    );
  }
}

String _$obd2ConnectionStatusHash() =>
    r'ab14da187622ea41fad1dbb4a80bd1bbe85e9082';

/// App-wide owner of the OBD2 connection status (#784).
///
/// Phase-1 scope: state machine + API for callers (boot probe,
/// manual disconnect, permission changes) to drive it. The actual
/// boot-time Bluetooth scan + auto-connect isolate is deferred to
/// the follow-up PR so this lands without coupling to the native
/// plugin surface.

abstract class _$Obd2ConnectionStatus
    extends $Notifier<Obd2ConnectionSnapshot> {
  Obd2ConnectionSnapshot build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<Obd2ConnectionSnapshot, Obd2ConnectionSnapshot>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Obd2ConnectionSnapshot, Obd2ConnectionSnapshot>,
              Obd2ConnectionSnapshot,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
