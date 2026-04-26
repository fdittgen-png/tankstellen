import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/report/providers/report_form_provider.dart';
import 'package:tankstellen/features/report/presentation/screens/report_screen.dart';

void main() {
  group('ReportFormState', () {
    test('default constructor has null selectedType and isSubmitting=false',
        () {
      const state = ReportFormState();
      expect(state.selectedType, isNull);
      expect(state.isSubmitting, isFalse);
    });

    test('constructor accepts explicit values', () {
      const state = ReportFormState(
        selectedType: ReportType.wrongE5,
        isSubmitting: true,
      );
      expect(state.selectedType, ReportType.wrongE5);
      expect(state.isSubmitting, isTrue);
    });

    group('copyWith', () {
      test('returns identical state when called with no arguments', () {
        const state = ReportFormState(
          selectedType: ReportType.wrongDiesel,
          isSubmitting: true,
        );
        final copy = state.copyWith();
        expect(copy.selectedType, ReportType.wrongDiesel);
        expect(copy.isSubmitting, isTrue);
      });

      test('selectedType param updates only that field', () {
        const state = ReportFormState(isSubmitting: true);
        final copy = state.copyWith(selectedType: ReportType.wrongName);
        expect(copy.selectedType, ReportType.wrongName);
        expect(copy.isSubmitting, isTrue);
      });

      test('isSubmitting param updates only that field', () {
        const state = ReportFormState(selectedType: ReportType.wrongAddress);
        final copy = state.copyWith(isSubmitting: true);
        expect(copy.selectedType, ReportType.wrongAddress);
        expect(copy.isSubmitting, isTrue);
      });

      test(
          'clearSelectedType=true clears non-null selection (no selectedType '
          'arg)', () {
        const state = ReportFormState(selectedType: ReportType.wrongE10);
        final copy = state.copyWith(clearSelectedType: true);
        expect(copy.selectedType, isNull);
      });

      test(
          'clearSelectedType=true wins over a non-null selectedType arg '
          '(clearSelectedType branch precedence)', () {
        const state = ReportFormState(selectedType: ReportType.wrongE10);
        final copy = state.copyWith(
          selectedType: ReportType.wrongDiesel,
          clearSelectedType: true,
        );
        expect(copy.selectedType, isNull);
      });

      test('clearSelectedType=true preserves isSubmitting flag', () {
        const state = ReportFormState(
          selectedType: ReportType.wrongE10,
          isSubmitting: true,
        );
        final copy = state.copyWith(clearSelectedType: true);
        expect(copy.selectedType, isNull);
        expect(copy.isSubmitting, isTrue);
      });
    });
  });

  group('ReportFormController', () {
    test('initial state has no selection and is not submitting', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(reportFormControllerProvider);
      expect(state.selectedType, isNull);
      expect(state.isSubmitting, isFalse);
    });

    test('build() returns the const default ReportFormState', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(reportFormControllerProvider);
      // The default state has both fields at their zero values.
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

    test('selectType with a non-null value sets selectedType', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(reportFormControllerProvider.notifier);

      notifier.selectType(ReportType.wrongE5);
      expect(
        container.read(reportFormControllerProvider).selectedType,
        ReportType.wrongE5,
      );
    });

    test(
        'selectType(null) clears a previously-set selection via the '
        'clearSelectedType branch', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(reportFormControllerProvider.notifier);

      notifier.selectType(ReportType.wrongDiesel);
      expect(
        container.read(reportFormControllerProvider).selectedType,
        ReportType.wrongDiesel,
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

    test('setSubmitting does not affect selectedType', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(reportFormControllerProvider.notifier);

      notifier.selectType(ReportType.wrongName);
      notifier.setSubmitting(true);
      expect(
        container.read(reportFormControllerProvider).selectedType,
        ReportType.wrongName,
      );
      expect(
        container.read(reportFormControllerProvider).isSubmitting,
        isTrue,
      );

      notifier.setSubmitting(false);
      expect(
        container.read(reportFormControllerProvider).selectedType,
        ReportType.wrongName,
      );
      expect(
        container.read(reportFormControllerProvider).isSubmitting,
        isFalse,
      );
    });

    test(
        'sequence: selectType then setSubmitting then selectType(null) '
        'combines correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(reportFormControllerProvider.notifier);

      notifier.selectType(ReportType.wrongAddress);
      expect(
        container.read(reportFormControllerProvider).selectedType,
        ReportType.wrongAddress,
      );
      expect(
        container.read(reportFormControllerProvider).isSubmitting,
        isFalse,
      );

      notifier.setSubmitting(true);
      expect(
        container.read(reportFormControllerProvider).selectedType,
        ReportType.wrongAddress,
      );
      expect(
        container.read(reportFormControllerProvider).isSubmitting,
        isTrue,
      );

      notifier.selectType(null);
      expect(
        container.read(reportFormControllerProvider).selectedType,
        isNull,
      );
      // setSubmitting flag survives a clear.
      expect(
        container.read(reportFormControllerProvider).isSubmitting,
        isTrue,
      );
    });
  });
}
