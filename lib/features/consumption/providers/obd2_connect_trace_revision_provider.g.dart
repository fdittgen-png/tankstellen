// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'obd2_connect_trace_revision_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A monotonically-increasing revision the OBD2 health screen watches so it
/// rebuilds when a NEW connect trace lands — including a LIVE reconnect /
/// first-connect failure the user never triggered from the screen (#2969).
///
/// The health screen read `Obd2CommDiagnostics.instance` / the trace log ONCE
/// per build with no listen, so a trace captured while the screen was open
/// stayed invisible until re-navigation. This provider bridges the static
/// [Obd2ConnectTraceLog] (deliberately Riverpod-free plumbing) to the widget
/// tree: the log calls a registered notify hook on every `endTrace`, the
/// provider bumps its int, and the screen's `ref.watch` rebuilds + re-reads the
/// (now larger) ring.
///
/// `keepAlive` so the revision survives the screen rebuilding on every bump.

@ProviderFor(Obd2ConnectTraceRevision)
final obd2ConnectTraceRevisionProvider = Obd2ConnectTraceRevisionProvider._();

/// A monotonically-increasing revision the OBD2 health screen watches so it
/// rebuilds when a NEW connect trace lands — including a LIVE reconnect /
/// first-connect failure the user never triggered from the screen (#2969).
///
/// The health screen read `Obd2CommDiagnostics.instance` / the trace log ONCE
/// per build with no listen, so a trace captured while the screen was open
/// stayed invisible until re-navigation. This provider bridges the static
/// [Obd2ConnectTraceLog] (deliberately Riverpod-free plumbing) to the widget
/// tree: the log calls a registered notify hook on every `endTrace`, the
/// provider bumps its int, and the screen's `ref.watch` rebuilds + re-reads the
/// (now larger) ring.
///
/// `keepAlive` so the revision survives the screen rebuilding on every bump.
final class Obd2ConnectTraceRevisionProvider
    extends $NotifierProvider<Obd2ConnectTraceRevision, int> {
  /// A monotonically-increasing revision the OBD2 health screen watches so it
  /// rebuilds when a NEW connect trace lands — including a LIVE reconnect /
  /// first-connect failure the user never triggered from the screen (#2969).
  ///
  /// The health screen read `Obd2CommDiagnostics.instance` / the trace log ONCE
  /// per build with no listen, so a trace captured while the screen was open
  /// stayed invisible until re-navigation. This provider bridges the static
  /// [Obd2ConnectTraceLog] (deliberately Riverpod-free plumbing) to the widget
  /// tree: the log calls a registered notify hook on every `endTrace`, the
  /// provider bumps its int, and the screen's `ref.watch` rebuilds + re-reads the
  /// (now larger) ring.
  ///
  /// `keepAlive` so the revision survives the screen rebuilding on every bump.
  Obd2ConnectTraceRevisionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'obd2ConnectTraceRevisionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$obd2ConnectTraceRevisionHash();

  @$internal
  @override
  Obd2ConnectTraceRevision create() => Obd2ConnectTraceRevision();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$obd2ConnectTraceRevisionHash() =>
    r'6f4dc5ea8c3f2615a0c17fc34f61662b3ea6ebb0';

/// A monotonically-increasing revision the OBD2 health screen watches so it
/// rebuilds when a NEW connect trace lands — including a LIVE reconnect /
/// first-connect failure the user never triggered from the screen (#2969).
///
/// The health screen read `Obd2CommDiagnostics.instance` / the trace log ONCE
/// per build with no listen, so a trace captured while the screen was open
/// stayed invisible until re-navigation. This provider bridges the static
/// [Obd2ConnectTraceLog] (deliberately Riverpod-free plumbing) to the widget
/// tree: the log calls a registered notify hook on every `endTrace`, the
/// provider bumps its int, and the screen's `ref.watch` rebuilds + re-reads the
/// (now larger) ring.
///
/// `keepAlive` so the revision survives the screen rebuilding on every bump.

abstract class _$Obd2ConnectTraceRevision extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
