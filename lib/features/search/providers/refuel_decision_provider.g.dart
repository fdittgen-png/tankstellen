// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'refuel_decision_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The three answers for the current result set (#4090, epic #4087).
///
/// Keyed on the already-filtered-and-sorted list so the decision follows
/// what the user is actually looking at: hide a brand and the
/// recommendation changes with it, which is the only honest behaviour
/// when the header claims to name the best of what is on screen.
///
/// EV rows are excluded. The economics is litres and L/100 km; a charger
/// has neither, and inventing a conversion to keep it in the ranking
/// would be exactly the fabricated authority `docs/specs/refuel-
/// economics.md` §3 forbids.
///
/// Distances are the crow-flies figures the result carries, so
/// [RefuelCandidate.isRoadDistance] stays false and the spec's 1.3
/// road factor applies. When #3633-style road distances are available
/// for a row, passing them here with the flag set is the only change
/// needed — the arithmetic below does not move.

@ProviderFor(refuelDecision)
final refuelDecisionProvider = RefuelDecisionFamily._();

/// The three answers for the current result set (#4090, epic #4087).
///
/// Keyed on the already-filtered-and-sorted list so the decision follows
/// what the user is actually looking at: hide a brand and the
/// recommendation changes with it, which is the only honest behaviour
/// when the header claims to name the best of what is on screen.
///
/// EV rows are excluded. The economics is litres and L/100 km; a charger
/// has neither, and inventing a conversion to keep it in the ranking
/// would be exactly the fabricated authority `docs/specs/refuel-
/// economics.md` §3 forbids.
///
/// Distances are the crow-flies figures the result carries, so
/// [RefuelCandidate.isRoadDistance] stays false and the spec's 1.3
/// road factor applies. When #3633-style road distances are available
/// for a row, passing them here with the flag set is the only change
/// needed — the arithmetic below does not move.

final class RefuelDecisionProvider
    extends $FunctionalProvider<RefuelDecision, RefuelDecision, RefuelDecision>
    with $Provider<RefuelDecision> {
  /// The three answers for the current result set (#4090, epic #4087).
  ///
  /// Keyed on the already-filtered-and-sorted list so the decision follows
  /// what the user is actually looking at: hide a brand and the
  /// recommendation changes with it, which is the only honest behaviour
  /// when the header claims to name the best of what is on screen.
  ///
  /// EV rows are excluded. The economics is litres and L/100 km; a charger
  /// has neither, and inventing a conversion to keep it in the ranking
  /// would be exactly the fabricated authority `docs/specs/refuel-
  /// economics.md` §3 forbids.
  ///
  /// Distances are the crow-flies figures the result carries, so
  /// [RefuelCandidate.isRoadDistance] stays false and the spec's 1.3
  /// road factor applies. When #3633-style road distances are available
  /// for a row, passing them here with the flag set is the only change
  /// needed — the arithmetic below does not move.
  RefuelDecisionProvider._({
    required RefuelDecisionFamily super.from,
    required List<SearchResultItem> super.argument,
  }) : super(
         retry: null,
         name: r'refuelDecisionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$refuelDecisionHash();

  @override
  String toString() {
    return r'refuelDecisionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<RefuelDecision> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RefuelDecision create(Ref ref) {
    final argument = this.argument as List<SearchResultItem>;
    return refuelDecision(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RefuelDecision value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RefuelDecision>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RefuelDecisionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$refuelDecisionHash() => r'91fb40324404f5eadae51aaf95e32848e68f5819';

/// The three answers for the current result set (#4090, epic #4087).
///
/// Keyed on the already-filtered-and-sorted list so the decision follows
/// what the user is actually looking at: hide a brand and the
/// recommendation changes with it, which is the only honest behaviour
/// when the header claims to name the best of what is on screen.
///
/// EV rows are excluded. The economics is litres and L/100 km; a charger
/// has neither, and inventing a conversion to keep it in the ranking
/// would be exactly the fabricated authority `docs/specs/refuel-
/// economics.md` §3 forbids.
///
/// Distances are the crow-flies figures the result carries, so
/// [RefuelCandidate.isRoadDistance] stays false and the spec's 1.3
/// road factor applies. When #3633-style road distances are available
/// for a row, passing them here with the flag set is the only change
/// needed — the arithmetic below does not move.

final class RefuelDecisionFamily extends $Family
    with $FunctionalFamilyOverride<RefuelDecision, List<SearchResultItem>> {
  RefuelDecisionFamily._()
    : super(
        retry: null,
        name: r'refuelDecisionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The three answers for the current result set (#4090, epic #4087).
  ///
  /// Keyed on the already-filtered-and-sorted list so the decision follows
  /// what the user is actually looking at: hide a brand and the
  /// recommendation changes with it, which is the only honest behaviour
  /// when the header claims to name the best of what is on screen.
  ///
  /// EV rows are excluded. The economics is litres and L/100 km; a charger
  /// has neither, and inventing a conversion to keep it in the ranking
  /// would be exactly the fabricated authority `docs/specs/refuel-
  /// economics.md` §3 forbids.
  ///
  /// Distances are the crow-flies figures the result carries, so
  /// [RefuelCandidate.isRoadDistance] stays false and the spec's 1.3
  /// road factor applies. When #3633-style road distances are available
  /// for a row, passing them here with the flag set is the only change
  /// needed — the arithmetic below does not move.

  RefuelDecisionProvider call(List<SearchResultItem> items) =>
      RefuelDecisionProvider._(argument: items, from: this);

  @override
  String toString() => r'refuelDecisionProvider';
}
