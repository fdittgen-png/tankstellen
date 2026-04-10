import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../presentation/screens/report_screen.dart';

part 'report_form_provider.g.dart';

/// UI state for the community report screen.
///
/// Holds the selected report type and submission progress. The price
/// text controller is owned by the screen (Flutter lifecycle).
class ReportFormState {
  final ReportType? selectedType;
  final bool isSubmitting;

  const ReportFormState({
    this.selectedType,
    this.isSubmitting = false,
  });

  ReportFormState copyWith({
    ReportType? selectedType,
    bool? isSubmitting,
    bool clearSelectedType = false,
  }) {
    return ReportFormState(
      selectedType:
          clearSelectedType ? null : (selectedType ?? this.selectedType),
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

@riverpod
class ReportFormController extends _$ReportFormController {
  @override
  ReportFormState build() => const ReportFormState();

  void selectType(ReportType? type) {
    state = state.copyWith(
      selectedType: type,
      clearSelectedType: type == null,
    );
  }

  void setSubmitting(bool value) {
    state = state.copyWith(isSubmitting: value);
  }
}
