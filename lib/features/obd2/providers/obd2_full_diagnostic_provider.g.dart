// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'obd2_full_diagnostic_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// #4548 (Epic #4547) — the opt-in "Full diagnostic recording" switch.
///
/// When on, every OBD2 trip additionally writes a raw per-command trace
/// (every request + reply at its own millisecond timestamp), polls the
/// car's health PIDs and trouble codes continuously (#4549) and takes a
/// start/stop identity snapshot (#4550). Read once per trip by the
/// recording pipeline. Off by default — it costs adapter bandwidth and
/// storage, and exists to analyse a car fault.

@ProviderFor(Obd2FullDiagnosticRecording)
final obd2FullDiagnosticRecordingProvider =
    Obd2FullDiagnosticRecordingProvider._();

/// #4548 (Epic #4547) — the opt-in "Full diagnostic recording" switch.
///
/// When on, every OBD2 trip additionally writes a raw per-command trace
/// (every request + reply at its own millisecond timestamp), polls the
/// car's health PIDs and trouble codes continuously (#4549) and takes a
/// start/stop identity snapshot (#4550). Read once per trip by the
/// recording pipeline. Off by default — it costs adapter bandwidth and
/// storage, and exists to analyse a car fault.
final class Obd2FullDiagnosticRecordingProvider
    extends $NotifierProvider<Obd2FullDiagnosticRecording, bool> {
  /// #4548 (Epic #4547) — the opt-in "Full diagnostic recording" switch.
  ///
  /// When on, every OBD2 trip additionally writes a raw per-command trace
  /// (every request + reply at its own millisecond timestamp), polls the
  /// car's health PIDs and trouble codes continuously (#4549) and takes a
  /// start/stop identity snapshot (#4550). Read once per trip by the
  /// recording pipeline. Off by default — it costs adapter bandwidth and
  /// storage, and exists to analyse a car fault.
  Obd2FullDiagnosticRecordingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'obd2FullDiagnosticRecordingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$obd2FullDiagnosticRecordingHash();

  @$internal
  @override
  Obd2FullDiagnosticRecording create() => Obd2FullDiagnosticRecording();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$obd2FullDiagnosticRecordingHash() =>
    r'1e615daa0a3e39d7d11e397b8be1dfd6bbf56506';

/// #4548 (Epic #4547) — the opt-in "Full diagnostic recording" switch.
///
/// When on, every OBD2 trip additionally writes a raw per-command trace
/// (every request + reply at its own millisecond timestamp), polls the
/// car's health PIDs and trouble codes continuously (#4549) and takes a
/// start/stop identity snapshot (#4550). Read once per trip by the
/// recording pipeline. Off by default — it costs adapter bandwidth and
/// storage, and exists to analyse a car fault.

abstract class _$Obd2FullDiagnosticRecording extends $Notifier<bool> {
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

/// #4551 — the stored full-diagnostic recordings, newest first.
/// Invalidate after a delete or when a trip ends.

@ProviderFor(obd2DiagnosticRecordings)
final obd2DiagnosticRecordingsProvider = Obd2DiagnosticRecordingsProvider._();

/// #4551 — the stored full-diagnostic recordings, newest first.
/// Invalidate after a delete or when a trip ends.

final class Obd2DiagnosticRecordingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Obd2DiagnosticRecording>>,
          List<Obd2DiagnosticRecording>,
          FutureOr<List<Obd2DiagnosticRecording>>
        >
    with
        $FutureModifier<List<Obd2DiagnosticRecording>>,
        $FutureProvider<List<Obd2DiagnosticRecording>> {
  /// #4551 — the stored full-diagnostic recordings, newest first.
  /// Invalidate after a delete or when a trip ends.
  Obd2DiagnosticRecordingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'obd2DiagnosticRecordingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$obd2DiagnosticRecordingsHash();

  @$internal
  @override
  $FutureProviderElement<List<Obd2DiagnosticRecording>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Obd2DiagnosticRecording>> create(Ref ref) {
    return obd2DiagnosticRecordings(ref);
  }
}

String _$obd2DiagnosticRecordingsHash() =>
    r'e05372161a8582a3eea2ca4d3f91d18bc2311b5d';

/// #4552 — the per-system health report of the recording at [path],
/// analysed on a worker isolate (a long trace is tens of MB of NDJSON).

@ProviderFor(obd2DiagnosticReport)
final obd2DiagnosticReportProvider = Obd2DiagnosticReportFamily._();

/// #4552 — the per-system health report of the recording at [path],
/// analysed on a worker isolate (a long trace is tens of MB of NDJSON).

final class Obd2DiagnosticReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<DiagnosticReport>,
          DiagnosticReport,
          FutureOr<DiagnosticReport>
        >
    with $FutureModifier<DiagnosticReport>, $FutureProvider<DiagnosticReport> {
  /// #4552 — the per-system health report of the recording at [path],
  /// analysed on a worker isolate (a long trace is tens of MB of NDJSON).
  Obd2DiagnosticReportProvider._({
    required Obd2DiagnosticReportFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'obd2DiagnosticReportProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$obd2DiagnosticReportHash();

  @override
  String toString() {
    return r'obd2DiagnosticReportProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<DiagnosticReport> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DiagnosticReport> create(Ref ref) {
    final argument = this.argument as String;
    return obd2DiagnosticReport(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is Obd2DiagnosticReportProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$obd2DiagnosticReportHash() =>
    r'2a658359935bb0b472505d27b9ad1f15bcf02cb7';

/// #4552 — the per-system health report of the recording at [path],
/// analysed on a worker isolate (a long trace is tens of MB of NDJSON).

final class Obd2DiagnosticReportFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<DiagnosticReport>, String> {
  Obd2DiagnosticReportFamily._()
    : super(
        retry: null,
        name: r'obd2DiagnosticReportProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// #4552 — the per-system health report of the recording at [path],
  /// analysed on a worker isolate (a long trace is tens of MB of NDJSON).

  Obd2DiagnosticReportProvider call(String path) =>
      Obd2DiagnosticReportProvider._(argument: path, from: this);

  @override
  String toString() => r'obd2DiagnosticReportProvider';
}
