// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'fuel_and_tank_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// What the next fill should optimise (#4278), persisted in the settings
/// box as the [FillObjective] name. Defaults to lowest cost per km; a
/// name this build does not know falls back to the default too.

@ProviderFor(FillObjectiveSetting)
final fillObjectiveSettingProvider = FillObjectiveSettingProvider._();

/// What the next fill should optimise (#4278), persisted in the settings
/// box as the [FillObjective] name. Defaults to lowest cost per km; a
/// name this build does not know falls back to the default too.
final class FillObjectiveSettingProvider
    extends $NotifierProvider<FillObjectiveSetting, FillObjective> {
  /// What the next fill should optimise (#4278), persisted in the settings
  /// box as the [FillObjective] name. Defaults to lowest cost per km; a
  /// name this build does not know falls back to the default too.
  FillObjectiveSettingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fillObjectiveSettingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fillObjectiveSettingHash();

  @$internal
  @override
  FillObjectiveSetting create() => FillObjectiveSetting();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FillObjective value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FillObjective>(value),
    );
  }
}

String _$fillObjectiveSettingHash() =>
    r'1577ac8dcfeda7a341955df7fdc79557ce993e94';

/// What the next fill should optimise (#4278), persisted in the settings
/// box as the [FillObjective] name. Defaults to lowest cost per km; a
/// name this build does not know falls back to the default too.

abstract class _$FillObjectiveSetting extends $Notifier<FillObjective> {
  FillObjective build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<FillObjective, FillObjective>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FillObjective, FillObjective>,
              FillObjective,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// The approvals [vehicleId]'s profile vouches for (#4278) — see
/// [vehicleFuelCapabilityOf], which reads the persisted declared grades
/// (#4324).

@ProviderFor(vehicleFuelCapability)
final vehicleFuelCapabilityProvider = VehicleFuelCapabilityFamily._();

/// The approvals [vehicleId]'s profile vouches for (#4278) — see
/// [vehicleFuelCapabilityOf], which reads the persisted declared grades
/// (#4324).

final class VehicleFuelCapabilityProvider
    extends
        $FunctionalProvider<
          VehicleFuelCapability,
          VehicleFuelCapability,
          VehicleFuelCapability
        >
    with $Provider<VehicleFuelCapability> {
  /// The approvals [vehicleId]'s profile vouches for (#4278) — see
  /// [vehicleFuelCapabilityOf], which reads the persisted declared grades
  /// (#4324).
  VehicleFuelCapabilityProvider._({
    required VehicleFuelCapabilityFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'vehicleFuelCapabilityProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$vehicleFuelCapabilityHash();

  @override
  String toString() {
    return r'vehicleFuelCapabilityProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<VehicleFuelCapability> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VehicleFuelCapability create(Ref ref) {
    final argument = this.argument as String;
    return vehicleFuelCapability(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VehicleFuelCapability value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VehicleFuelCapability>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is VehicleFuelCapabilityProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$vehicleFuelCapabilityHash() =>
    r'f4012aa9bf41635a40e768d632195d19ad162e53';

/// The approvals [vehicleId]'s profile vouches for (#4278) — see
/// [vehicleFuelCapabilityOf], which reads the persisted declared grades
/// (#4324).

final class VehicleFuelCapabilityFamily extends $Family
    with $FunctionalFamilyOverride<VehicleFuelCapability, String> {
  VehicleFuelCapabilityFamily._()
    : super(
        retry: null,
        name: r'vehicleFuelCapabilityProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The approvals [vehicleId]'s profile vouches for (#4278) — see
  /// [vehicleFuelCapabilityOf], which reads the persisted declared grades
  /// (#4324).

  VehicleFuelCapabilityProvider call(String vehicleId) =>
      VehicleFuelCapabilityProvider._(argument: vehicleId, from: this);

  @override
  String toString() => r'vehicleFuelCapabilityProvider';
}

/// The offers for the priceable grades, from prices the app ALREADY holds
/// — opening the surface never costs a network call.
///
/// #4324 — the last search's results come first: each station carries its
/// distance, so the decision prices the detour (`RefuelEconomics`).
/// Reading [searchStateProvider] never searches; with no search this
/// session it is empty. Only then the favourite stations' cached prices
/// (#4278), which carry no distance, so no detour is priced. The two are
/// never mixed: a detour-free favourite would undercut every priced one.

@ProviderFor(nextFillOffers)
final nextFillOffersProvider = NextFillOffersFamily._();

/// The offers for the priceable grades, from prices the app ALREADY holds
/// — opening the surface never costs a network call.
///
/// #4324 — the last search's results come first: each station carries its
/// distance, so the decision prices the detour (`RefuelEconomics`).
/// Reading [searchStateProvider] never searches; with no search this
/// session it is empty. Only then the favourite stations' cached prices
/// (#4278), which carry no distance, so no detour is priced. The two are
/// never mixed: a detour-free favourite would undercut every priced one.

final class NextFillOffersProvider
    extends
        $FunctionalProvider<List<FuelOffer>, List<FuelOffer>, List<FuelOffer>>
    with $Provider<List<FuelOffer>> {
  /// The offers for the priceable grades, from prices the app ALREADY holds
  /// — opening the surface never costs a network call.
  ///
  /// #4324 — the last search's results come first: each station carries its
  /// distance, so the decision prices the detour (`RefuelEconomics`).
  /// Reading [searchStateProvider] never searches; with no search this
  /// session it is empty. Only then the favourite stations' cached prices
  /// (#4278), which carry no distance, so no detour is priced. The two are
  /// never mixed: a detour-free favourite would undercut every priced one.
  NextFillOffersProvider._({
    required NextFillOffersFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'nextFillOffersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$nextFillOffersHash();

  @override
  String toString() {
    return r'nextFillOffersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<FuelOffer>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<FuelOffer> create(Ref ref) {
    final argument = this.argument as String;
    return nextFillOffers(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<FuelOffer> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<FuelOffer>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is NextFillOffersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$nextFillOffersHash() => r'65c783f5b974c0977b12df812f033f4130639d20';

/// The offers for the priceable grades, from prices the app ALREADY holds
/// — opening the surface never costs a network call.
///
/// #4324 — the last search's results come first: each station carries its
/// distance, so the decision prices the detour (`RefuelEconomics`).
/// Reading [searchStateProvider] never searches; with no search this
/// session it is empty. Only then the favourite stations' cached prices
/// (#4278), which carry no distance, so no detour is priced. The two are
/// never mixed: a detour-free favourite would undercut every priced one.

final class NextFillOffersFamily extends $Family
    with $FunctionalFamilyOverride<List<FuelOffer>, String> {
  NextFillOffersFamily._()
    : super(
        retry: null,
        name: r'nextFillOffersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The offers for the priceable grades, from prices the app ALREADY holds
  /// — opening the surface never costs a network call.
  ///
  /// #4324 — the last search's results come first: each station carries its
  /// distance, so the decision prices the detour (`RefuelEconomics`).
  /// Reading [searchStateProvider] never searches; with no search this
  /// session it is empty. Only then the favourite stations' cached prices
  /// (#4278), which carry no distance, so no detour is priced. The two are
  /// never mixed: a detour-free favourite would undercut every priced one.

  NextFillOffersProvider call(String vehicleId) =>
      NextFillOffersProvider._(argument: vehicleId, from: this);

  @override
  String toString() => r'nextFillOffersProvider';
}

/// The decision request for [vehicleId]: objective, capability, offers.
/// Value-equal, so the decision provider recomputes only when one of them
/// actually changes.

@ProviderFor(nextFillRequest)
final nextFillRequestProvider = NextFillRequestFamily._();

/// The decision request for [vehicleId]: objective, capability, offers.
/// Value-equal, so the decision provider recomputes only when one of them
/// actually changes.

final class NextFillRequestProvider
    extends
        $FunctionalProvider<NextFillRequest, NextFillRequest, NextFillRequest>
    with $Provider<NextFillRequest> {
  /// The decision request for [vehicleId]: objective, capability, offers.
  /// Value-equal, so the decision provider recomputes only when one of them
  /// actually changes.
  NextFillRequestProvider._({
    required NextFillRequestFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'nextFillRequestProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$nextFillRequestHash();

  @override
  String toString() {
    return r'nextFillRequestProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<NextFillRequest> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NextFillRequest create(Ref ref) {
    final argument = this.argument as String;
    return nextFillRequest(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NextFillRequest value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NextFillRequest>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is NextFillRequestProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$nextFillRequestHash() => r'8d1b9cdabc51fb6c1b3b71be898537c981388916';

/// The decision request for [vehicleId]: objective, capability, offers.
/// Value-equal, so the decision provider recomputes only when one of them
/// actually changes.

final class NextFillRequestFamily extends $Family
    with $FunctionalFamilyOverride<NextFillRequest, String> {
  NextFillRequestFamily._()
    : super(
        retry: null,
        name: r'nextFillRequestProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The decision request for [vehicleId]: objective, capability, offers.
  /// Value-equal, so the decision provider recomputes only when one of them
  /// actually changes.

  NextFillRequestProvider call(String vehicleId) =>
      NextFillRequestProvider._(argument: vehicleId, from: this);

  @override
  String toString() => r'nextFillRequestProvider';
}

/// Everything the Fuel & Tank surface renders for [vehicleId] (#4278),
/// from the canonical providers: the evidence-only tank blend (#4279),
/// the learned behaviour profile (#4276) and the next-fill decision
/// (#4277).

@ProviderFor(fuelAndTankView)
final fuelAndTankViewProvider = FuelAndTankViewFamily._();

/// Everything the Fuel & Tank surface renders for [vehicleId] (#4278),
/// from the canonical providers: the evidence-only tank blend (#4279),
/// the learned behaviour profile (#4276) and the next-fill decision
/// (#4277).

final class FuelAndTankViewProvider
    extends
        $FunctionalProvider<FuelAndTankView, FuelAndTankView, FuelAndTankView>
    with $Provider<FuelAndTankView> {
  /// Everything the Fuel & Tank surface renders for [vehicleId] (#4278),
  /// from the canonical providers: the evidence-only tank blend (#4279),
  /// the learned behaviour profile (#4276) and the next-fill decision
  /// (#4277).
  FuelAndTankViewProvider._({
    required FuelAndTankViewFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'fuelAndTankViewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fuelAndTankViewHash();

  @override
  String toString() {
    return r'fuelAndTankViewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<FuelAndTankView> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FuelAndTankView create(Ref ref) {
    final argument = this.argument as String;
    return fuelAndTankView(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FuelAndTankView value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FuelAndTankView>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FuelAndTankViewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fuelAndTankViewHash() => r'e560b135c6c66f4050e8461660b46a43afdc2425';

/// Everything the Fuel & Tank surface renders for [vehicleId] (#4278),
/// from the canonical providers: the evidence-only tank blend (#4279),
/// the learned behaviour profile (#4276) and the next-fill decision
/// (#4277).

final class FuelAndTankViewFamily extends $Family
    with $FunctionalFamilyOverride<FuelAndTankView, String> {
  FuelAndTankViewFamily._()
    : super(
        retry: null,
        name: r'fuelAndTankViewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Everything the Fuel & Tank surface renders for [vehicleId] (#4278),
  /// from the canonical providers: the evidence-only tank blend (#4279),
  /// the learned behaviour profile (#4276) and the next-fill decision
  /// (#4277).

  FuelAndTankViewProvider call(String vehicleId) =>
      FuelAndTankViewProvider._(argument: vehicleId, from: this);

  @override
  String toString() => r'fuelAndTankViewProvider';
}
