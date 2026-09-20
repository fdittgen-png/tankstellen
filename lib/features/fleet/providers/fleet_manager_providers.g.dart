// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'fleet_manager_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The manager dashboard's server seam.

@ProviderFor(fleetMetricsReader)
final fleetMetricsReaderProvider = FleetMetricsReaderProvider._();

/// The manager dashboard's server seam.

final class FleetMetricsReaderProvider
    extends
        $FunctionalProvider<
          FleetMetricsReader,
          FleetMetricsReader,
          FleetMetricsReader
        >
    with $Provider<FleetMetricsReader> {
  /// The manager dashboard's server seam.
  FleetMetricsReaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fleetMetricsReaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fleetMetricsReaderHash();

  @$internal
  @override
  $ProviderElement<FleetMetricsReader> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FleetMetricsReader create(Ref ref) {
    return fleetMetricsReader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FleetMetricsReader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FleetMetricsReader>(value),
    );
  }
}

String _$fleetMetricsReaderHash() =>
    r'e68fe46abc159b303521db2721dd265589651947';

/// The signed-in user a manager action is stamped with, or the empty
/// string when nobody is signed in.
///
/// Only the DEVICE's copy of the history uses it. The server stamps
/// `fleet_audit_events.actor` from `auth.uid()` inside the definer
/// body, so a client that lied here would produce a local history that
/// disagrees with the trail — and the trail is the one that counts.

@ProviderFor(fleetActingUserId)
final fleetActingUserIdProvider = FleetActingUserIdProvider._();

/// The signed-in user a manager action is stamped with, or the empty
/// string when nobody is signed in.
///
/// Only the DEVICE's copy of the history uses it. The server stamps
/// `fleet_audit_events.actor` from `auth.uid()` inside the definer
/// body, so a client that lied here would produce a local history that
/// disagrees with the trail — and the trail is the one that counts.

final class FleetActingUserIdProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// The signed-in user a manager action is stamped with, or the empty
  /// string when nobody is signed in.
  ///
  /// Only the DEVICE's copy of the history uses it. The server stamps
  /// `fleet_audit_events.actor` from `auth.uid()` inside the definer
  /// body, so a client that lied here would produce a local history that
  /// disagrees with the trail — and the trail is the one that counts.
  FleetActingUserIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fleetActingUserIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fleetActingUserIdHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return fleetActingUserId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$fleetActingUserIdHash() => r'8d456455be76c048c50e376eac73efd56344403e';

/// The organisation the manager surfaces report on, as this device
/// last pulled it.
///
/// **This is the slice's one wiring point.** F3 (#4212 tail) owns
/// `FleetScope` — the provider that resolves membership, role and
/// directory freshness — and it is not on this branch. Rather than
/// guess at its shape, F9 reads the directory through this override
/// point: it returns null here, every manager screen renders its "no
/// fleet on this device" state, and the integrator replaces the body
/// with the scope's directory in one line. Tests override it directly.
///
/// The directory is also where the threshold and the vehicle names
/// come from, so wiring this one provider lights the whole surface.

@ProviderFor(fleetManagerDirectory)
final fleetManagerDirectoryProvider = FleetManagerDirectoryProvider._();

/// The organisation the manager surfaces report on, as this device
/// last pulled it.
///
/// **This is the slice's one wiring point.** F3 (#4212 tail) owns
/// `FleetScope` — the provider that resolves membership, role and
/// directory freshness — and it is not on this branch. Rather than
/// guess at its shape, F9 reads the directory through this override
/// point: it returns null here, every manager screen renders its "no
/// fleet on this device" state, and the integrator replaces the body
/// with the scope's directory in one line. Tests override it directly.
///
/// The directory is also where the threshold and the vehicle names
/// come from, so wiring this one provider lights the whole surface.

final class FleetManagerDirectoryProvider
    extends
        $FunctionalProvider<FleetDirectory?, FleetDirectory?, FleetDirectory?>
    with $Provider<FleetDirectory?> {
  /// The organisation the manager surfaces report on, as this device
  /// last pulled it.
  ///
  /// **This is the slice's one wiring point.** F3 (#4212 tail) owns
  /// `FleetScope` — the provider that resolves membership, role and
  /// directory freshness — and it is not on this branch. Rather than
  /// guess at its shape, F9 reads the directory through this override
  /// point: it returns null here, every manager screen renders its "no
  /// fleet on this device" state, and the integrator replaces the body
  /// with the scope's directory in one line. Tests override it directly.
  ///
  /// The directory is also where the threshold and the vehicle names
  /// come from, so wiring this one provider lights the whole surface.
  FleetManagerDirectoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fleetManagerDirectoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fleetManagerDirectoryHash();

  @$internal
  @override
  $ProviderElement<FleetDirectory?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FleetDirectory? create(Ref ref) {
    return fleetManagerDirectory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FleetDirectory? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FleetDirectory?>(value),
    );
  }
}

String _$fleetManagerDirectoryHash() =>
    r'bfa4c78f9072bd4413b986d60486b9cd8f4d8638';

/// The organisation's own aggregation threshold, or the placeholder
/// default (D9). Floored at 1: suppression is not switchable off.

@ProviderFor(fleetAggregationMinSamples)
final fleetAggregationMinSamplesProvider =
    FleetAggregationMinSamplesProvider._();

/// The organisation's own aggregation threshold, or the placeholder
/// default (D9). Floored at 1: suppression is not switchable off.

final class FleetAggregationMinSamplesProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// The organisation's own aggregation threshold, or the placeholder
  /// default (D9). Floored at 1: suppression is not switchable off.
  FleetAggregationMinSamplesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fleetAggregationMinSamplesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fleetAggregationMinSamplesHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return fleetAggregationMinSamples(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$fleetAggregationMinSamplesHash() =>
    r'4c2842976b79246ec066df8c7b3c72f15767bc40';

/// The reporting window, defaulting to the last 90 days.
///
/// Ninety days because the fleet figures are built from fill-ups and
/// a shorter window on a vehicle refuelled fortnightly would sit under
/// the suppression threshold by construction — the dashboard would
/// show nothing and blame privacy for what is really the period.

@ProviderFor(FleetReportPeriod)
final fleetReportPeriodProvider = FleetReportPeriodProvider._();

/// The reporting window, defaulting to the last 90 days.
///
/// Ninety days because the fleet figures are built from fill-ups and
/// a shorter window on a vehicle refuelled fortnightly would sit under
/// the suppression threshold by construction — the dashboard would
/// show nothing and blame privacy for what is really the period.
final class FleetReportPeriodProvider
    extends $NotifierProvider<FleetReportPeriod, FleetPeriod> {
  /// The reporting window, defaulting to the last 90 days.
  ///
  /// Ninety days because the fleet figures are built from fill-ups and
  /// a shorter window on a vehicle refuelled fortnightly would sit under
  /// the suppression threshold by construction — the dashboard would
  /// show nothing and blame privacy for what is really the period.
  FleetReportPeriodProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fleetReportPeriodProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fleetReportPeriodHash();

  @$internal
  @override
  FleetReportPeriod create() => FleetReportPeriod();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FleetPeriod value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FleetPeriod>(value),
    );
  }
}

String _$fleetReportPeriodHash() => r'd28ca9934cb1a01516de315761d64e8a72ef0f06';

/// The reporting window, defaulting to the last 90 days.
///
/// Ninety days because the fleet figures are built from fill-ups and
/// a shorter window on a vehicle refuelled fortnightly would sit under
/// the suppression threshold by construction — the dashboard would
/// show nothing and blame privacy for what is really the period.

abstract class _$FleetReportPeriod extends $Notifier<FleetPeriod> {
  FleetPeriod build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<FleetPeriod, FleetPeriod>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FleetPeriod, FleetPeriod>,
              FleetPeriod,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// The period's aggregate, or null when the question could not be
/// asked (no fleet on this device, no session, a server that refused).
///
/// Null is not "an empty fleet". The screens render two different
/// states, because a manager who is told their vehicles bought no fuel
/// when really the phone is offline has been told something false.

@ProviderFor(fleetPeriodKpis)
final fleetPeriodKpisProvider = FleetPeriodKpisProvider._();

/// The period's aggregate, or null when the question could not be
/// asked (no fleet on this device, no session, a server that refused).
///
/// Null is not "an empty fleet". The screens render two different
/// states, because a manager who is told their vehicles bought no fuel
/// when really the phone is offline has been told something false.

final class FleetPeriodKpisProvider
    extends
        $FunctionalProvider<
          AsyncValue<FleetKpis?>,
          FleetKpis?,
          FutureOr<FleetKpis?>
        >
    with $FutureModifier<FleetKpis?>, $FutureProvider<FleetKpis?> {
  /// The period's aggregate, or null when the question could not be
  /// asked (no fleet on this device, no session, a server that refused).
  ///
  /// Null is not "an empty fleet". The screens render two different
  /// states, because a manager who is told their vehicles bought no fuel
  /// when really the phone is offline has been told something false.
  FleetPeriodKpisProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fleetPeriodKpisProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fleetPeriodKpisHash();

  @$internal
  @override
  $FutureProviderElement<FleetKpis?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<FleetKpis?> create(Ref ref) {
    return fleetPeriodKpis(ref);
  }
}

String _$fleetPeriodKpisHash() => r'86bee73743f8717bdde434ea1a04a3d80db8660d';

/// The "Needs attention" list for the current period — empty when
/// there is nothing to report, never a placeholder.

@ProviderFor(fleetAttentionItems)
final fleetAttentionItemsProvider = FleetAttentionItemsProvider._();

/// The "Needs attention" list for the current period — empty when
/// there is nothing to report, never a placeholder.

final class FleetAttentionItemsProvider
    extends
        $FunctionalProvider<
          List<FleetAttentionItem>,
          List<FleetAttentionItem>,
          List<FleetAttentionItem>
        >
    with $Provider<List<FleetAttentionItem>> {
  /// The "Needs attention" list for the current period — empty when
  /// there is nothing to report, never a placeholder.
  FleetAttentionItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fleetAttentionItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fleetAttentionItemsHash();

  @$internal
  @override
  $ProviderElement<List<FleetAttentionItem>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<FleetAttentionItem> create(Ref ref) {
    return fleetAttentionItems(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<FleetAttentionItem> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<FleetAttentionItem>>(value),
    );
  }
}

String _$fleetAttentionItemsHash() =>
    r'2109d24c944d00fff660a615f1e6f791ee4f21e2';

/// The organisation's expense review queue (#4215 shipped the server
/// half and the workflow; #4216 gives it a screen).
///
/// Drafts never appear: the policy stops them server-side and
/// `decodeReviewQueue` drops one that somehow arrived anyway.

@ProviderFor(fleetReviewQueue)
final fleetReviewQueueProvider = FleetReviewQueueProvider._();

/// The organisation's expense review queue (#4215 shipped the server
/// half and the workflow; #4216 gives it a screen).
///
/// Drafts never appear: the policy stops them server-side and
/// `decodeReviewQueue` drops one that somehow arrived anyway.

final class FleetReviewQueueProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Expense>>,
          List<Expense>,
          FutureOr<List<Expense>>
        >
    with $FutureModifier<List<Expense>>, $FutureProvider<List<Expense>> {
  /// The organisation's expense review queue (#4215 shipped the server
  /// half and the workflow; #4216 gives it a screen).
  ///
  /// Drafts never appear: the policy stops them server-side and
  /// `decodeReviewQueue` drops one that somehow arrived anyway.
  FleetReviewQueueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fleetReviewQueueProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fleetReviewQueueHash();

  @$internal
  @override
  $FutureProviderElement<List<Expense>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Expense>> create(Ref ref) {
    return fleetReviewQueue(ref);
  }
}

String _$fleetReviewQueueHash() => r'79827f1da0b08a4375e9db9fe56296dbecfa55b4';

/// One vehicle's figures for the current period, or null when the
/// period holds no row for it at all.

@ProviderFor(fleetVehicleMetricsById)
final fleetVehicleMetricsByIdProvider = FleetVehicleMetricsByIdFamily._();

/// One vehicle's figures for the current period, or null when the
/// period holds no row for it at all.

final class FleetVehicleMetricsByIdProvider
    extends
        $FunctionalProvider<
          FleetVehicleMetrics?,
          FleetVehicleMetrics?,
          FleetVehicleMetrics?
        >
    with $Provider<FleetVehicleMetrics?> {
  /// One vehicle's figures for the current period, or null when the
  /// period holds no row for it at all.
  FleetVehicleMetricsByIdProvider._({
    required FleetVehicleMetricsByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'fleetVehicleMetricsByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fleetVehicleMetricsByIdHash();

  @override
  String toString() {
    return r'fleetVehicleMetricsByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<FleetVehicleMetrics?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FleetVehicleMetrics? create(Ref ref) {
    final argument = this.argument as String;
    return fleetVehicleMetricsById(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FleetVehicleMetrics? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FleetVehicleMetrics?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FleetVehicleMetricsByIdProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fleetVehicleMetricsByIdHash() =>
    r'ecfaefd9175ee717486dd756e03789aa500a749e';

/// One vehicle's figures for the current period, or null when the
/// period holds no row for it at all.

final class FleetVehicleMetricsByIdFamily extends $Family
    with $FunctionalFamilyOverride<FleetVehicleMetrics?, String> {
  FleetVehicleMetricsByIdFamily._()
    : super(
        retry: null,
        name: r'fleetVehicleMetricsByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One vehicle's figures for the current period, or null when the
  /// period holds no row for it at all.

  FleetVehicleMetricsByIdProvider call(String fleetVehicleId) =>
      FleetVehicleMetricsByIdProvider._(argument: fleetVehicleId, from: this);

  @override
  String toString() => r'fleetVehicleMetricsByIdProvider';
}

/// The org's own name for a vehicle, or null when this device's
/// directory does not know it. Never a plate unless the organisation
/// chose to publish a masked one.

@ProviderFor(fleetVehicleRowById)
final fleetVehicleRowByIdProvider = FleetVehicleRowByIdFamily._();

/// The org's own name for a vehicle, or null when this device's
/// directory does not know it. Never a plate unless the organisation
/// chose to publish a masked one.

final class FleetVehicleRowByIdProvider
    extends
        $FunctionalProvider<
          FleetVehicleRow?,
          FleetVehicleRow?,
          FleetVehicleRow?
        >
    with $Provider<FleetVehicleRow?> {
  /// The org's own name for a vehicle, or null when this device's
  /// directory does not know it. Never a plate unless the organisation
  /// chose to publish a masked one.
  FleetVehicleRowByIdProvider._({
    required FleetVehicleRowByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'fleetVehicleRowByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fleetVehicleRowByIdHash();

  @override
  String toString() {
    return r'fleetVehicleRowByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<FleetVehicleRow?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FleetVehicleRow? create(Ref ref) {
    final argument = this.argument as String;
    return fleetVehicleRowById(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FleetVehicleRow? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FleetVehicleRow?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FleetVehicleRowByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fleetVehicleRowByIdHash() =>
    r'15b415ced7e4b2c748dc1c5b52a8d6cc1b35ecdc';

/// The org's own name for a vehicle, or null when this device's
/// directory does not know it. Never a plate unless the organisation
/// chose to publish a masked one.

final class FleetVehicleRowByIdFamily extends $Family
    with $FunctionalFamilyOverride<FleetVehicleRow?, String> {
  FleetVehicleRowByIdFamily._()
    : super(
        retry: null,
        name: r'fleetVehicleRowByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The org's own name for a vehicle, or null when this device's
  /// directory does not know it. Never a plate unless the organisation
  /// chose to publish a masked one.

  FleetVehicleRowByIdProvider call(String fleetVehicleId) =>
      FleetVehicleRowByIdProvider._(argument: fleetVehicleId, from: this);

  @override
  String toString() => r'fleetVehicleRowByIdProvider';
}
