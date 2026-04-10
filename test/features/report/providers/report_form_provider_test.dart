import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/report/providers/report_form_provider.dart';
import 'package:tankstellen/features/report/presentation/screens/report_screen.dart';

void main() {
  group('ReportFormController', () {
    test('initial state has no selection and is not submitting', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(reportFormControllerProvider);
      expect(state.selectedType, isNull);
      expect(state.isSubmitting, isFalse);
    });

    test('selectType updates selection and can be cleared', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(reportFormControllerProvider.notifier);

      notifier.selectType(ReportType.wrongE10);
      expect(
        container.read(reportFormControllerProvider).selectedType,
        ReportType.wrongE10,
      );

      notifier.selectType(null);
      expect(
        container.read(reportFormControllerProvider).selectedType,
        isNull,
      );
    });

    test('setSubmitting toggles submission flag', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(reportFormControllerProvider.notifier);

      notifier.setSubmitting(true);
      expect(
        container.read(reportFormControllerProvider).isSubmitting,
        isTrue,
      );

      notifier.setSubmitting(false);
      expect(
        container.read(reportFormControllerProvider).isSubmitting,
        isFalse,
      );
    });
  });
}
