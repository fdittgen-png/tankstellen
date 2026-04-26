// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loyalty_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Hive-backed loyalty repository (#1120 pilot). Returns null when the
/// settings box isn't open — widget tests that skip Hive init get a
/// silent no-op instead of a thrown error.

@ProviderFor(loyaltyCardRepository)
final loyaltyCardRepositoryProvider = LoyaltyCardRepositoryProvider._();

/// Hive-backed loyalty repository (#1120 pilot). Returns null when the
/// settings box isn't open — widget tests that skip Hive init get a
/// silent no-op instead of a thrown error.

final class LoyaltyCardRepositoryProvider
    extends
        $FunctionalProvider<
          LoyaltyCardRepository?,
          LoyaltyCardRepository?,
          LoyaltyCardRepository?
        >
    with $Provider<LoyaltyCardRepository?> {
  /// Hive-backed loyalty repository (#1120 pilot). Returns null when the
  /// settings box isn't open — widget tests that skip Hive init get a
  /// silent no-op instead of a thrown error.
  LoyaltyCardRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loyaltyCardRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loyaltyCardRepositoryHash();

  @$internal
  @override
  $ProviderElement<LoyaltyCardRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LoyaltyCardRepository? create(Ref ref) {
    return loyaltyCardRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LoyaltyCardRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LoyaltyCardRepository?>(value),
    );
  }
}

String _$loyaltyCardRepositoryHash() =>
    r'c61a4ab067a2ac31dcc2e383dd2b87e64c511de7';

/// Reactive list of every persisted loyalty card, newest-first.
///
/// Mutations go through this notifier so the UI rebuilds without
/// having to invalidate the provider manually. Disabled cards stay
/// in the list (the settings sub-screen needs them) — the consumer
/// that decides whether a discount applies should look at
/// [activeDiscountByBrandProvider] instead, which already filters by
/// `enabled`.

@ProviderFor(LoyaltyCards)
final loyaltyCardsProvider = LoyaltyCardsProvider._();

/// Reactive list of every persisted loyalty card, newest-first.
///
/// Mutations go through this notifier so the UI rebuilds without
/// having to invalidate the provider manually. Disabled cards stay
/// in the list (the settings sub-screen needs them) — the consumer
/// that decides whether a discount applies should look at
/// [activeDiscountByBrandProvider] instead, which already filters by
/// `enabled`.
final class LoyaltyCardsProvider
    extends $NotifierProvider<LoyaltyCards, List<LoyaltyCard>> {
  /// Reactive list of every persisted loyalty card, newest-first.
  ///
  /// Mutations go through this notifier so the UI rebuilds without
  /// having to invalidate the provider manually. Disabled cards stay
  /// in the list (the settings sub-screen needs them) — the consumer
  /// that decides whether a discount applies should look at
  /// [activeDiscountByBrandProvider] instead, which already filters by
  /// `enabled`.
  LoyaltyCardsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loyaltyCardsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loyaltyCardsHash();

  @$internal
  @override
  LoyaltyCards create() => LoyaltyCards();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<LoyaltyCard> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<LoyaltyCard>>(value),
    );
  }
}

String _$loyaltyCardsHash() => r'64cfec8629a1e5481754f465ae5345f98869ab94';

/// Reactive list of every persisted loyalty card, newest-first.
///
/// Mutations go through this notifier so the UI rebuilds without
/// having to invalidate the provider manually. Disabled cards stay
/// in the list (the settings sub-screen needs them) — the consumer
/// that decides whether a discount applies should look at
/// [activeDiscountByBrandProvider] instead, which already filters by
/// `enabled`.

abstract class _$LoyaltyCards extends $Notifier<List<LoyaltyCard>> {
  List<LoyaltyCard> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<LoyaltyCard>, List<LoyaltyCard>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<LoyaltyCard>, List<LoyaltyCard>>,
              List<LoyaltyCard>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Per-brand active discount lookup table (#1120).
///
/// The map collapses every enabled card down to the *largest*
/// per-litre discount on the user's books for that brand — if the
/// user has registered two Total cards (e.g. "Personal" 0.04 €/L
/// and "Company" 0.06 €/L) the price-display layer applies the
/// better one rather than summing them. Disabled cards are filtered
/// out here so consumers don't have to repeat the rule.

@ProviderFor(activeDiscountByBrand)
final activeDiscountByBrandProvider = ActiveDiscountByBrandProvider._();

/// Per-brand active discount lookup table (#1120).
///
/// The map collapses every enabled card down to the *largest*
/// per-litre discount on the user's books for that brand — if the
/// user has registered two Total cards (e.g. "Personal" 0.04 €/L
/// and "Company" 0.06 €/L) the price-display layer applies the
/// better one rather than summing them. Disabled cards are filtered
/// out here so consumers don't have to repeat the rule.

final class ActiveDiscountByBrandProvider
    extends
        $FunctionalProvider<
          Map<LoyaltyBrand, double>,
          Map<LoyaltyBrand, double>,
          Map<LoyaltyBrand, double>
        >
    with $Provider<Map<LoyaltyBrand, double>> {
  /// Per-brand active discount lookup table (#1120).
  ///
  /// The map collapses every enabled card down to the *largest*
  /// per-litre discount on the user's books for that brand — if the
  /// user has registered two Total cards (e.g. "Personal" 0.04 €/L
  /// and "Company" 0.06 €/L) the price-display layer applies the
  /// better one rather than summing them. Disabled cards are filtered
  /// out here so consumers don't have to repeat the rule.
  ActiveDiscountByBrandProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeDiscountByBrandProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeDiscountByBrandHash();

  @$internal
  @override
  $ProviderElement<Map<LoyaltyBrand, double>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<LoyaltyBrand, double> create(Ref ref) {
    return activeDiscountByBrand(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<LoyaltyBrand, double> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<LoyaltyBrand, double>>(value),
    );
  }
}

String _$activeDiscountByBrandHash() =>
    r'e015ba567f84b43a84b63c48f2c5ed12096b81ca';
