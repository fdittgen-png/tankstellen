// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'obd2_connection_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide owner of the OBD2 connection status (#784).

@ProviderFor(Obd2ConnectionStatus)
final obd2ConnectionStatusProvider = Obd2ConnectionStatusProvider._();

/// App-wide owner of the OBD2 connection status (#784).
final class Obd2ConnectionStatusProvider
    extends $NotifierProvider<Obd2ConnectionStatus, Obd2ConnectionSnapshot> {
  /// App-wide owner of the OBD2 connection status (#784).
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
    r'35b5d18c18098aaa886bcddafac954ff48a98ba5';

/// App-wide owner of the OBD2 connection status (#784).

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
