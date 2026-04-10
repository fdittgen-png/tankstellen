// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_form_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ReportFormController)
final reportFormControllerProvider = ReportFormControllerProvider._();

final class ReportFormControllerProvider
    extends $NotifierProvider<ReportFormController, ReportFormState> {
  ReportFormControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reportFormControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reportFormControllerHash();

  @$internal
  @override
  ReportFormController create() => ReportFormController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReportFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReportFormState>(value),
    );
  }
}

String _$reportFormControllerHash() =>
    r'270a488ffa8daf7399b19abcc11048e2a479dc49';

abstract class _$ReportFormController extends $Notifier<ReportFormState> {
  ReportFormState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ReportFormState, ReportFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ReportFormState, ReportFormState>,
              ReportFormState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
