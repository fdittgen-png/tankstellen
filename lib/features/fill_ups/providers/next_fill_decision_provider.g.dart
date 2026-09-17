// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'next_fill_decision_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether [vehicleId]'s next fill should change fuel under [request]
/// (#4277).
///
/// A pure function of the current tank blend (#4279), the learned
/// behaviour profile (#4276) and the request — so it recomputes when the
/// history changes and is identical for identical inputs. The caller owns
/// the request: the objective, the offers at hand, and the vehicle's
/// approvals (`VehicleFuelCapability`, #4274). No persisted capability
/// exists yet, so an unknown one yields
/// [NextFillOutcome.compatibilityUnknown] rather than a guess.

@ProviderFor(nextFillDecision)
final nextFillDecisionProvider = NextFillDecisionFamily._();

/// Whether [vehicleId]'s next fill should change fuel under [request]
/// (#4277).
///
/// A pure function of the current tank blend (#4279), the learned
/// behaviour profile (#4276) and the request — so it recomputes when the
/// history changes and is identical for identical inputs. The caller owns
/// the request: the objective, the offers at hand, and the vehicle's
/// approvals (`VehicleFuelCapability`, #4274). No persisted capability
/// exists yet, so an unknown one yields
/// [NextFillOutcome.compatibilityUnknown] rather than a guess.

final class NextFillDecisionProvider
    extends
        $FunctionalProvider<
          NextFillDecision,
          NextFillDecision,
          NextFillDecision
        >
    with $Provider<NextFillDecision> {
  /// Whether [vehicleId]'s next fill should change fuel under [request]
  /// (#4277).
  ///
  /// A pure function of the current tank blend (#4279), the learned
  /// behaviour profile (#4276) and the request — so it recomputes when the
  /// history changes and is identical for identical inputs. The caller owns
  /// the request: the objective, the offers at hand, and the vehicle's
  /// approvals (`VehicleFuelCapability`, #4274). No persisted capability
  /// exists yet, so an unknown one yields
  /// [NextFillOutcome.compatibilityUnknown] rather than a guess.
  NextFillDecisionProvider._({
    required NextFillDecisionFamily super.from,
    required (String, NextFillRequest) super.argument,
  }) : super(
         retry: null,
         name: r'nextFillDecisionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$nextFillDecisionHash();

  @override
  String toString() {
    return r'nextFillDecisionProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<NextFillDecision> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NextFillDecision create(Ref ref) {
    final argument = this.argument as (String, NextFillRequest);
    return nextFillDecision(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NextFillDecision value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NextFillDecision>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is NextFillDecisionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$nextFillDecisionHash() => r'0d903763b8f47aa37239bae97f009546eb31582d';

/// Whether [vehicleId]'s next fill should change fuel under [request]
/// (#4277).
///
/// A pure function of the current tank blend (#4279), the learned
/// behaviour profile (#4276) and the request — so it recomputes when the
/// history changes and is identical for identical inputs. The caller owns
/// the request: the objective, the offers at hand, and the vehicle's
/// approvals (`VehicleFuelCapability`, #4274). No persisted capability
/// exists yet, so an unknown one yields
/// [NextFillOutcome.compatibilityUnknown] rather than a guess.

final class NextFillDecisionFamily extends $Family
    with
        $FunctionalFamilyOverride<NextFillDecision, (String, NextFillRequest)> {
  NextFillDecisionFamily._()
    : super(
        retry: null,
        name: r'nextFillDecisionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether [vehicleId]'s next fill should change fuel under [request]
  /// (#4277).
  ///
  /// A pure function of the current tank blend (#4279), the learned
  /// behaviour profile (#4276) and the request — so it recomputes when the
  /// history changes and is identical for identical inputs. The caller owns
  /// the request: the objective, the offers at hand, and the vehicle's
  /// approvals (`VehicleFuelCapability`, #4274). No persisted capability
  /// exists yet, so an unknown one yields
  /// [NextFillOutcome.compatibilityUnknown] rather than a guess.

  NextFillDecisionProvider call(String vehicleId, NextFillRequest request) =>
      NextFillDecisionProvider._(argument: (vehicleId, request), from: this);

  @override
  String toString() => r'nextFillDecisionProvider';
}
