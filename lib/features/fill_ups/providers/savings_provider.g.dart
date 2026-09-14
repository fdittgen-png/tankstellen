// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'savings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// What the active vehicle saved against its own normal price (#4136).
///
/// Derived from the fill-ups rather than stored, so it can never drift
/// from them — see [SavingsLedger] for why that was the better call than
/// the Hive box the issue proposed.

@ProviderFor(savingsLedger)
final savingsLedgerProvider = SavingsLedgerProvider._();

/// What the active vehicle saved against its own normal price (#4136).
///
/// Derived from the fill-ups rather than stored, so it can never drift
/// from them — see [SavingsLedger] for why that was the better call than
/// the Hive box the issue proposed.

final class SavingsLedgerProvider
    extends $FunctionalProvider<SavingsLedger, SavingsLedger, SavingsLedger>
    with $Provider<SavingsLedger> {
  /// What the active vehicle saved against its own normal price (#4136).
  ///
  /// Derived from the fill-ups rather than stored, so it can never drift
  /// from them — see [SavingsLedger] for why that was the better call than
  /// the Hive box the issue proposed.
  SavingsLedgerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savingsLedgerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savingsLedgerHash();

  @$internal
  @override
  $ProviderElement<SavingsLedger> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SavingsLedger create(Ref ref) {
    return savingsLedger(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SavingsLedger value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SavingsLedger>(value),
    );
  }
}

String _$savingsLedgerHash() => r'0813645dd21adb729f0aeb720d59fe1436239683';
