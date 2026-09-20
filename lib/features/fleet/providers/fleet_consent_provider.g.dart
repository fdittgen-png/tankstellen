// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'fleet_consent_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the user has consented to sharing fleet data with their org.
///
/// `false` whenever the master cloud-sync consent is off, whatever is
/// stored — the same force-off rule `GdprConsent.save` applies to
/// `consentSyncTrips`.

@ProviderFor(FleetSharingConsent)
final fleetSharingConsentProvider = FleetSharingConsentProvider._();

/// Whether the user has consented to sharing fleet data with their org.
///
/// `false` whenever the master cloud-sync consent is off, whatever is
/// stored — the same force-off rule `GdprConsent.save` applies to
/// `consentSyncTrips`.
final class FleetSharingConsentProvider
    extends $NotifierProvider<FleetSharingConsent, bool> {
  /// Whether the user has consented to sharing fleet data with their org.
  ///
  /// `false` whenever the master cloud-sync consent is off, whatever is
  /// stored — the same force-off rule `GdprConsent.save` applies to
  /// `consentSyncTrips`.
  FleetSharingConsentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fleetSharingConsentProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fleetSharingConsentHash();

  @$internal
  @override
  FleetSharingConsent create() => FleetSharingConsent();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$fleetSharingConsentHash() =>
    r'8070dd39191dff3a945e16db5e02a1813804ee62';

/// Whether the user has consented to sharing fleet data with their org.
///
/// `false` whenever the master cloud-sync consent is off, whatever is
/// stored — the same force-off rule `GdprConsent.save` applies to
/// `consentSyncTrips`.

abstract class _$FleetSharingConsent extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
