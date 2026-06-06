// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'obd2_self_test_adapter_choice.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The MAC the user picked for the next self-test run (#2938). `null` ⇒ the
/// "Scan for adapter" fallback (the legacy blind scan). The family is keyed by
/// the [defaultMac] (the active vehicle's paired adapter) so the dropdown
/// starts on the sensible default without an init-time write — selecting the
/// scan fallback explicitly is a [set]`(null)`.
///
/// `keepAlive` so the choice survives the health screen rebuilding on every
/// diagnostics-collector tick (an autoDispose notifier would reset mid-run).

@ProviderFor(Obd2SelfTestSelectedAdapter)
final obd2SelfTestSelectedAdapterProvider =
    Obd2SelfTestSelectedAdapterFamily._();

/// The MAC the user picked for the next self-test run (#2938). `null` ⇒ the
/// "Scan for adapter" fallback (the legacy blind scan). The family is keyed by
/// the [defaultMac] (the active vehicle's paired adapter) so the dropdown
/// starts on the sensible default without an init-time write — selecting the
/// scan fallback explicitly is a [set]`(null)`.
///
/// `keepAlive` so the choice survives the health screen rebuilding on every
/// diagnostics-collector tick (an autoDispose notifier would reset mid-run).
final class Obd2SelfTestSelectedAdapterProvider
    extends $NotifierProvider<Obd2SelfTestSelectedAdapter, String?> {
  /// The MAC the user picked for the next self-test run (#2938). `null` ⇒ the
  /// "Scan for adapter" fallback (the legacy blind scan). The family is keyed by
  /// the [defaultMac] (the active vehicle's paired adapter) so the dropdown
  /// starts on the sensible default without an init-time write — selecting the
  /// scan fallback explicitly is a [set]`(null)`.
  ///
  /// `keepAlive` so the choice survives the health screen rebuilding on every
  /// diagnostics-collector tick (an autoDispose notifier would reset mid-run).
  Obd2SelfTestSelectedAdapterProvider._({
    required Obd2SelfTestSelectedAdapterFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'obd2SelfTestSelectedAdapterProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$obd2SelfTestSelectedAdapterHash();

  @override
  String toString() {
    return r'obd2SelfTestSelectedAdapterProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  Obd2SelfTestSelectedAdapter create() => Obd2SelfTestSelectedAdapter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Obd2SelfTestSelectedAdapterProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$obd2SelfTestSelectedAdapterHash() =>
    r'625c08933408ef76314e1eda51bc8d135e9404ab';

/// The MAC the user picked for the next self-test run (#2938). `null` ⇒ the
/// "Scan for adapter" fallback (the legacy blind scan). The family is keyed by
/// the [defaultMac] (the active vehicle's paired adapter) so the dropdown
/// starts on the sensible default without an init-time write — selecting the
/// scan fallback explicitly is a [set]`(null)`.
///
/// `keepAlive` so the choice survives the health screen rebuilding on every
/// diagnostics-collector tick (an autoDispose notifier would reset mid-run).

final class Obd2SelfTestSelectedAdapterFamily extends $Family
    with
        $ClassFamilyOverride<
          Obd2SelfTestSelectedAdapter,
          String?,
          String?,
          String?,
          String?
        > {
  Obd2SelfTestSelectedAdapterFamily._()
    : super(
        retry: null,
        name: r'obd2SelfTestSelectedAdapterProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// The MAC the user picked for the next self-test run (#2938). `null` ⇒ the
  /// "Scan for adapter" fallback (the legacy blind scan). The family is keyed by
  /// the [defaultMac] (the active vehicle's paired adapter) so the dropdown
  /// starts on the sensible default without an init-time write — selecting the
  /// scan fallback explicitly is a [set]`(null)`.
  ///
  /// `keepAlive` so the choice survives the health screen rebuilding on every
  /// diagnostics-collector tick (an autoDispose notifier would reset mid-run).

  Obd2SelfTestSelectedAdapterProvider call(String? defaultMac) =>
      Obd2SelfTestSelectedAdapterProvider._(argument: defaultMac, from: this);

  @override
  String toString() => r'obd2SelfTestSelectedAdapterProvider';
}

/// The MAC the user picked for the next self-test run (#2938). `null` ⇒ the
/// "Scan for adapter" fallback (the legacy blind scan). The family is keyed by
/// the [defaultMac] (the active vehicle's paired adapter) so the dropdown
/// starts on the sensible default without an init-time write — selecting the
/// scan fallback explicitly is a [set]`(null)`.
///
/// `keepAlive` so the choice survives the health screen rebuilding on every
/// diagnostics-collector tick (an autoDispose notifier would reset mid-run).

abstract class _$Obd2SelfTestSelectedAdapter extends $Notifier<String?> {
  late final _$args = ref.$arg as String?;
  String? get defaultMac => _$args;

  String? build(String? defaultMac);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
