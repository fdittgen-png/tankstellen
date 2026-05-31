// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calculator_prefill_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Resolves the [CalculatorPrefill] from the live app state. Kept as a
/// provider (not inline in the screen) so the resolution priority is
/// independently testable and the screen stays thin.

@ProviderFor(calculatorPrefill)
final calculatorPrefillProvider = CalculatorPrefillProvider._();

/// Resolves the [CalculatorPrefill] from the live app state. Kept as a
/// provider (not inline in the screen) so the resolution priority is
/// independently testable and the screen stays thin.

final class CalculatorPrefillProvider
    extends
        $FunctionalProvider<
          CalculatorPrefill,
          CalculatorPrefill,
          CalculatorPrefill
        >
    with $Provider<CalculatorPrefill> {
  /// Resolves the [CalculatorPrefill] from the live app state. Kept as a
  /// provider (not inline in the screen) so the resolution priority is
  /// independently testable and the screen stays thin.
  CalculatorPrefillProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calculatorPrefillProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calculatorPrefillHash();

  @$internal
  @override
  $ProviderElement<CalculatorPrefill> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalculatorPrefill create(Ref ref) {
    return calculatorPrefill(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalculatorPrefill value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalculatorPrefill>(value),
    );
  }
}

String _$calculatorPrefillHash() => r'7c5094cca41f38a9acc4b9d84731c1f35c981cbc';
