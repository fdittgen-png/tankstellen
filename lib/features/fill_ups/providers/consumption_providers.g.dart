// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'consumption_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Repository for reading/writing [FillUp] entries.

@ProviderFor(fillUpRepository)
final fillUpRepositoryProvider = FillUpRepositoryProvider._();

/// Repository for reading/writing [FillUp] entries.

final class FillUpRepositoryProvider
    extends
        $FunctionalProvider<
          FillUpRepository,
          FillUpRepository,
          FillUpRepository
        >
    with $Provider<FillUpRepository> {
  /// Repository for reading/writing [FillUp] entries.
  FillUpRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fillUpRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fillUpRepositoryHash();

  @$internal
  @override
  $ProviderElement<FillUpRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FillUpRepository create(Ref ref) {
    return fillUpRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FillUpRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FillUpRepository>(value),
    );
  }
}

String _$fillUpRepositoryHash() => r'cc5e51ddaa9f996875c6e5bace204386b25f55dd';

/// Learner for the per-vehicle pump-anchored fuel gain (#3887; replaced
/// the #815 η_v learner).
///
/// Returns null when the trip-history Hive box isn't open (widget
/// tests that don't bother initialising Hive) — callers guard by
/// skipping the reconciliation entirely when the instance is null,
/// which also lets the fill-up save path stay a single-line change.

@ProviderFor(pumpGainLearner)
final pumpGainLearnerProvider = PumpGainLearnerProvider._();

/// Learner for the per-vehicle pump-anchored fuel gain (#3887; replaced
/// the #815 η_v learner).
///
/// Returns null when the trip-history Hive box isn't open (widget
/// tests that don't bother initialising Hive) — callers guard by
/// skipping the reconciliation entirely when the instance is null,
/// which also lets the fill-up save path stay a single-line change.

final class PumpGainLearnerProvider
    extends
        $FunctionalProvider<
          PumpGainLearner?,
          PumpGainLearner?,
          PumpGainLearner?
        >
    with $Provider<PumpGainLearner?> {
  /// Learner for the per-vehicle pump-anchored fuel gain (#3887; replaced
  /// the #815 η_v learner).
  ///
  /// Returns null when the trip-history Hive box isn't open (widget
  /// tests that don't bother initialising Hive) — callers guard by
  /// skipping the reconciliation entirely when the instance is null,
  /// which also lets the fill-up save path stay a single-line change.
  PumpGainLearnerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pumpGainLearnerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pumpGainLearnerHash();

  @$internal
  @override
  $ProviderElement<PumpGainLearner?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PumpGainLearner? create(Ref ref) {
    return pumpGainLearner(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PumpGainLearner? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PumpGainLearner?>(value),
    );
  }
}

String _$pumpGainLearnerHash() => r'1e2570a937593cd31ff3cf2dfc1a5d09e886b3a9';

/// Detector for the broken-MAP belief system (#1423 phase 3). Single
/// stateless instance shared across observations.

@ProviderFor(brokenMapDetector)
final brokenMapDetectorProvider = BrokenMapDetectorProvider._();

/// Detector for the broken-MAP belief system (#1423 phase 3). Single
/// stateless instance shared across observations.

final class BrokenMapDetectorProvider
    extends
        $FunctionalProvider<
          BrokenMapDetector,
          BrokenMapDetector,
          BrokenMapDetector
        >
    with $Provider<BrokenMapDetector> {
  /// Detector for the broken-MAP belief system (#1423 phase 3). Single
  /// stateless instance shared across observations.
  BrokenMapDetectorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'brokenMapDetectorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$brokenMapDetectorHash();

  @$internal
  @override
  $ProviderElement<BrokenMapDetector> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BrokenMapDetector create(Ref ref) {
    return brokenMapDetector(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BrokenMapDetector value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BrokenMapDetector>(value),
    );
  }
}

String _$brokenMapDetectorHash() => r'401fe3bdd10c78d2b90c351588fea002125d89a2';

/// Persistent per-adapter broken-MAP blocklist (#1423 phase 4). Reads
/// and writes the latest belief confidence by ELM ID through the
/// shared [SettingsStorage] (Hive `settings` box). The populator
/// recalls before each pair attempt so a known-broken adapter
/// surfaces a warning without re-probing.

@ProviderFor(obdAdapterBlocklist)
final obdAdapterBlocklistProvider = ObdAdapterBlocklistProvider._();

/// Persistent per-adapter broken-MAP blocklist (#1423 phase 4). Reads
/// and writes the latest belief confidence by ELM ID through the
/// shared [SettingsStorage] (Hive `settings` box). The populator
/// recalls before each pair attempt so a known-broken adapter
/// surfaces a warning without re-probing.

final class ObdAdapterBlocklistProvider
    extends
        $FunctionalProvider<
          ObdAdapterBlocklist,
          ObdAdapterBlocklist,
          ObdAdapterBlocklist
        >
    with $Provider<ObdAdapterBlocklist> {
  /// Persistent per-adapter broken-MAP blocklist (#1423 phase 4). Reads
  /// and writes the latest belief confidence by ELM ID through the
  /// shared [SettingsStorage] (Hive `settings` box). The populator
  /// recalls before each pair attempt so a known-broken adapter
  /// surfaces a warning without re-probing.
  ObdAdapterBlocklistProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'obdAdapterBlocklistProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$obdAdapterBlocklistHash();

  @$internal
  @override
  $ProviderElement<ObdAdapterBlocklist> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ObdAdapterBlocklist create(Ref ref) {
    return obdAdapterBlocklist(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ObdAdapterBlocklist value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ObdAdapterBlocklist>(value),
    );
  }
}

String _$obdAdapterBlocklistHash() =>
    r'56c0d8086fe53973b194d6ba305a520e91b9783b';

/// Holds the most recent per-vehicle [BrokenMapBelief] (#1423 phase 3).
///
/// Hive-backed via [SettingsStorage] (#1423 phase 4) — beliefs survive
/// app restart. Lazy-loaded on first [beliefFor] call per vehicle;
/// [set] writes back to settings fire-and-forget. Errors are logged
/// via [errorLogger] but never propagate (a storage hiccup must not
/// break the fill-up save flow that triggered the update).
///
/// Keyed by `vehicleId`. Beliefs default to [BrokenMapBelief()] when
/// the vehicle hasn't been observed yet.

@ProviderFor(BrokenMapBeliefByVehicle)
final brokenMapBeliefByVehicleProvider = BrokenMapBeliefByVehicleProvider._();

/// Holds the most recent per-vehicle [BrokenMapBelief] (#1423 phase 3).
///
/// Hive-backed via [SettingsStorage] (#1423 phase 4) — beliefs survive
/// app restart. Lazy-loaded on first [beliefFor] call per vehicle;
/// [set] writes back to settings fire-and-forget. Errors are logged
/// via [errorLogger] but never propagate (a storage hiccup must not
/// break the fill-up save flow that triggered the update).
///
/// Keyed by `vehicleId`. Beliefs default to [BrokenMapBelief()] when
/// the vehicle hasn't been observed yet.
final class BrokenMapBeliefByVehicleProvider
    extends
        $NotifierProvider<
          BrokenMapBeliefByVehicle,
          Map<String, BrokenMapBelief>
        > {
  /// Holds the most recent per-vehicle [BrokenMapBelief] (#1423 phase 3).
  ///
  /// Hive-backed via [SettingsStorage] (#1423 phase 4) — beliefs survive
  /// app restart. Lazy-loaded on first [beliefFor] call per vehicle;
  /// [set] writes back to settings fire-and-forget. Errors are logged
  /// via [errorLogger] but never propagate (a storage hiccup must not
  /// break the fill-up save flow that triggered the update).
  ///
  /// Keyed by `vehicleId`. Beliefs default to [BrokenMapBelief()] when
  /// the vehicle hasn't been observed yet.
  BrokenMapBeliefByVehicleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'brokenMapBeliefByVehicleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$brokenMapBeliefByVehicleHash();

  @$internal
  @override
  BrokenMapBeliefByVehicle create() => BrokenMapBeliefByVehicle();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, BrokenMapBelief> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, BrokenMapBelief>>(value),
    );
  }
}

String _$brokenMapBeliefByVehicleHash() =>
    r'71c88cb42b8e1b5a779e523225437a962a7f27e1';

/// Holds the most recent per-vehicle [BrokenMapBelief] (#1423 phase 3).
///
/// Hive-backed via [SettingsStorage] (#1423 phase 4) — beliefs survive
/// app restart. Lazy-loaded on first [beliefFor] call per vehicle;
/// [set] writes back to settings fire-and-forget. Errors are logged
/// via [errorLogger] but never propagate (a storage hiccup must not
/// break the fill-up save flow that triggered the update).
///
/// Keyed by `vehicleId`. Beliefs default to [BrokenMapBelief()] when
/// the vehicle hasn't been observed yet.

abstract class _$BrokenMapBeliefByVehicle
    extends $Notifier<Map<String, BrokenMapBelief>> {
  Map<String, BrokenMapBelief> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<Map<String, BrokenMapBelief>, Map<String, BrokenMapBelief>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<String, BrokenMapBelief>,
                Map<String, BrokenMapBelief>
              >,
              Map<String, BrokenMapBelief>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Holds the most recent [PumpGainResult] (#3887) so the UI can show a
/// one-shot calibration snackbar after the fill-up save flow closes.
///
/// The fill-up screen reads-and-clears this on its way out; unread
/// results persist across widget rebuilds so the snackbar still fires
/// when the user lands on the consumption tab. Only the most recent
/// result is retained — if two tankfuls calibrate back-to-back (rare,
/// but possible during data imports) the second one wins.

@ProviderFor(LastPumpGainResult)
final lastPumpGainResultProvider = LastPumpGainResultProvider._();

/// Holds the most recent [PumpGainResult] (#3887) so the UI can show a
/// one-shot calibration snackbar after the fill-up save flow closes.
///
/// The fill-up screen reads-and-clears this on its way out; unread
/// results persist across widget rebuilds so the snackbar still fires
/// when the user lands on the consumption tab. Only the most recent
/// result is retained — if two tankfuls calibrate back-to-back (rare,
/// but possible during data imports) the second one wins.
final class LastPumpGainResultProvider
    extends $NotifierProvider<LastPumpGainResult, PumpGainResult?> {
  /// Holds the most recent [PumpGainResult] (#3887) so the UI can show a
  /// one-shot calibration snackbar after the fill-up save flow closes.
  ///
  /// The fill-up screen reads-and-clears this on its way out; unread
  /// results persist across widget rebuilds so the snackbar still fires
  /// when the user lands on the consumption tab. Only the most recent
  /// result is retained — if two tankfuls calibrate back-to-back (rare,
  /// but possible during data imports) the second one wins.
  LastPumpGainResultProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lastPumpGainResultProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lastPumpGainResultHash();

  @$internal
  @override
  LastPumpGainResult create() => LastPumpGainResult();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PumpGainResult? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PumpGainResult?>(value),
    );
  }
}

String _$lastPumpGainResultHash() =>
    r'b0d7fceadbb8c277a473bbd972c067d70c4e6d4c';

/// Holds the most recent [PumpGainResult] (#3887) so the UI can show a
/// one-shot calibration snackbar after the fill-up save flow closes.
///
/// The fill-up screen reads-and-clears this on its way out; unread
/// results persist across widget rebuilds so the snackbar still fires
/// when the user lands on the consumption tab. Only the most recent
/// result is retained — if two tankfuls calibrate back-to-back (rare,
/// but possible during data imports) the second one wins.

abstract class _$LastPumpGainResult extends $Notifier<PumpGainResult?> {
  PumpGainResult? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PumpGainResult?, PumpGainResult?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PumpGainResult?, PumpGainResult?>,
              PumpGainResult?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Mutable list of all fill-ups, newest first.

@ProviderFor(FillUpList)
final fillUpListProvider = FillUpListProvider._();

/// Mutable list of all fill-ups, newest first.
final class FillUpListProvider
    extends $NotifierProvider<FillUpList, List<FillUp>> {
  /// Mutable list of all fill-ups, newest first.
  FillUpListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fillUpListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fillUpListHash();

  @$internal
  @override
  FillUpList create() => FillUpList();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<FillUp> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<FillUp>>(value),
    );
  }
}

String _$fillUpListHash() => r'9b2fb6972c36d1b2a6c21fd8cd62822be528ac9e';

/// Mutable list of all fill-ups, newest first.

abstract class _$FillUpList extends $Notifier<List<FillUp>> {
  List<FillUp> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<FillUp>, List<FillUp>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<FillUp>, List<FillUp>>,
              List<FillUp>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Aggregated stats derived from the current fill-up list.

@ProviderFor(consumptionStats)
final consumptionStatsProvider = ConsumptionStatsProvider._();

/// Aggregated stats derived from the current fill-up list.

final class ConsumptionStatsProvider
    extends
        $FunctionalProvider<
          ConsumptionStats,
          ConsumptionStats,
          ConsumptionStats
        >
    with $Provider<ConsumptionStats> {
  /// Aggregated stats derived from the current fill-up list.
  ConsumptionStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'consumptionStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$consumptionStatsHash();

  @$internal
  @override
  $ProviderElement<ConsumptionStats> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ConsumptionStats create(Ref ref) {
    return consumptionStats(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConsumptionStats value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConsumptionStats>(value),
    );
  }
}

String _$consumptionStatsHash() => r'6613eff02126b04dc046d555deafd254b7211e9b';

/// Per-fill-up eco-score — compares this tank's L/100 km to the
/// rolling average over the last 3 same-fuel-type fill-ups.
///
/// Returns `null` for fill-ups where the score is not meaningful
/// (first-ever fill-up, odometer rollback, no same-fuel history).
/// Callers render nothing when the return is null.
///
/// Keyed by fill-up id so the Riverpod graph invalidates just the
/// affected card when a single fill-up is edited, not the whole list.
/// See #676 ("Smarter pump. Smarter drive. Save twice.").

@ProviderFor(ecoScoreForFillUp)
final ecoScoreForFillUpProvider = EcoScoreForFillUpFamily._();

/// Per-fill-up eco-score — compares this tank's L/100 km to the
/// rolling average over the last 3 same-fuel-type fill-ups.
///
/// Returns `null` for fill-ups where the score is not meaningful
/// (first-ever fill-up, odometer rollback, no same-fuel history).
/// Callers render nothing when the return is null.
///
/// Keyed by fill-up id so the Riverpod graph invalidates just the
/// affected card when a single fill-up is edited, not the whole list.
/// See #676 ("Smarter pump. Smarter drive. Save twice.").

final class EcoScoreForFillUpProvider
    extends $FunctionalProvider<EcoScore?, EcoScore?, EcoScore?>
    with $Provider<EcoScore?> {
  /// Per-fill-up eco-score — compares this tank's L/100 km to the
  /// rolling average over the last 3 same-fuel-type fill-ups.
  ///
  /// Returns `null` for fill-ups where the score is not meaningful
  /// (first-ever fill-up, odometer rollback, no same-fuel history).
  /// Callers render nothing when the return is null.
  ///
  /// Keyed by fill-up id so the Riverpod graph invalidates just the
  /// affected card when a single fill-up is edited, not the whole list.
  /// See #676 ("Smarter pump. Smarter drive. Save twice.").
  EcoScoreForFillUpProvider._({
    required EcoScoreForFillUpFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'ecoScoreForFillUpProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ecoScoreForFillUpHash();

  @override
  String toString() {
    return r'ecoScoreForFillUpProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<EcoScore?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EcoScore? create(Ref ref) {
    final argument = this.argument as String;
    return ecoScoreForFillUp(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EcoScore? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EcoScore?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EcoScoreForFillUpProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ecoScoreForFillUpHash() => r'd73756e1f350917069211ef38a04a8d020682ca3';

/// Per-fill-up eco-score — compares this tank's L/100 km to the
/// rolling average over the last 3 same-fuel-type fill-ups.
///
/// Returns `null` for fill-ups where the score is not meaningful
/// (first-ever fill-up, odometer rollback, no same-fuel history).
/// Callers render nothing when the return is null.
///
/// Keyed by fill-up id so the Riverpod graph invalidates just the
/// affected card when a single fill-up is edited, not the whole list.
/// See #676 ("Smarter pump. Smarter drive. Save twice.").

final class EcoScoreForFillUpFamily extends $Family
    with $FunctionalFamilyOverride<EcoScore?, String> {
  EcoScoreForFillUpFamily._()
    : super(
        retry: null,
        name: r'ecoScoreForFillUpProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Per-fill-up eco-score — compares this tank's L/100 km to the
  /// rolling average over the last 3 same-fuel-type fill-ups.
  ///
  /// Returns `null` for fill-ups where the score is not meaningful
  /// (first-ever fill-up, odometer rollback, no same-fuel history).
  /// Callers render nothing when the return is null.
  ///
  /// Keyed by fill-up id so the Riverpod graph invalidates just the
  /// affected card when a single fill-up is edited, not the whole list.
  /// See #676 ("Smarter pump. Smarter drive. Save twice.").

  EcoScoreForFillUpProvider call(String fillUpId) =>
      EcoScoreForFillUpProvider._(argument: fillUpId, from: this);

  @override
  String toString() => r'ecoScoreForFillUpProvider';
}

/// Raw per-fill-up L/100 km, with no baseline / no comparison (#2060).
///
/// Returns the per-entry consumption number even when
/// [ecoScoreForFillUp] is null because there isn't enough history
/// to build a rolling-average baseline. The card consumes this to
/// render a plain "X.X L/100 km" line on entries that would otherwise
/// be blank — the 2026-05-20 entry in the user's screenshot has the
/// distance + litres to compute a number, just not enough preceding
/// same-fuel entries for a trend.

@ProviderFor(litersPer100KmForFillUp)
final litersPer100KmForFillUpProvider = LitersPer100KmForFillUpFamily._();

/// Raw per-fill-up L/100 km, with no baseline / no comparison (#2060).
///
/// Returns the per-entry consumption number even when
/// [ecoScoreForFillUp] is null because there isn't enough history
/// to build a rolling-average baseline. The card consumes this to
/// render a plain "X.X L/100 km" line on entries that would otherwise
/// be blank — the 2026-05-20 entry in the user's screenshot has the
/// distance + litres to compute a number, just not enough preceding
/// same-fuel entries for a trend.

final class LitersPer100KmForFillUpProvider
    extends $FunctionalProvider<double?, double?, double?>
    with $Provider<double?> {
  /// Raw per-fill-up L/100 km, with no baseline / no comparison (#2060).
  ///
  /// Returns the per-entry consumption number even when
  /// [ecoScoreForFillUp] is null because there isn't enough history
  /// to build a rolling-average baseline. The card consumes this to
  /// render a plain "X.X L/100 km" line on entries that would otherwise
  /// be blank — the 2026-05-20 entry in the user's screenshot has the
  /// distance + litres to compute a number, just not enough preceding
  /// same-fuel entries for a trend.
  LitersPer100KmForFillUpProvider._({
    required LitersPer100KmForFillUpFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'litersPer100KmForFillUpProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$litersPer100KmForFillUpHash();

  @override
  String toString() {
    return r'litersPer100KmForFillUpProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<double?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double? create(Ref ref) {
    final argument = this.argument as String;
    return litersPer100KmForFillUp(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LitersPer100KmForFillUpProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$litersPer100KmForFillUpHash() =>
    r'6f61c26cafb27ca36198380bb9c75ac80b39c9f3';

/// Raw per-fill-up L/100 km, with no baseline / no comparison (#2060).
///
/// Returns the per-entry consumption number even when
/// [ecoScoreForFillUp] is null because there isn't enough history
/// to build a rolling-average baseline. The card consumes this to
/// render a plain "X.X L/100 km" line on entries that would otherwise
/// be blank — the 2026-05-20 entry in the user's screenshot has the
/// distance + litres to compute a number, just not enough preceding
/// same-fuel entries for a trend.

final class LitersPer100KmForFillUpFamily extends $Family
    with $FunctionalFamilyOverride<double?, String> {
  LitersPer100KmForFillUpFamily._()
    : super(
        retry: null,
        name: r'litersPer100KmForFillUpProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Raw per-fill-up L/100 km, with no baseline / no comparison (#2060).
  ///
  /// Returns the per-entry consumption number even when
  /// [ecoScoreForFillUp] is null because there isn't enough history
  /// to build a rolling-average baseline. The card consumes this to
  /// render a plain "X.X L/100 km" line on entries that would otherwise
  /// be blank — the 2026-05-20 entry in the user's screenshot has the
  /// distance + litres to compute a number, just not enough preceding
  /// same-fuel entries for a trend.

  LitersPer100KmForFillUpProvider call(String fillUpId) =>
      LitersPer100KmForFillUpProvider._(argument: fillUpId, from: this);

  @override
  String toString() => r'litersPer100KmForFillUpProvider';
}
