// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'opportunity_feed_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// What the background engine found, newest first (#4154).
///
/// A plain synchronous read: [OpportunityFeedStore] reads one Hive row
/// that is already open in this isolate, so there is no future to await
/// and no loading state to render. The background scan writes it; this
/// only ever reads.
///
/// **Expired entries are filtered out, not hidden.** An opportunity
/// carries an `expiresAt` because a price is not an opportunity forever,
/// and a feed that kept showing yesterday's bargain would teach the user
/// that the list is stale — the same failure a late notification causes
/// (#4149). They stay in the store until retention drops them; they just
/// stop being presented as current.
///
/// The clock comes through [appClockProvider] (#3660) rather than raw,
/// so a test can pin "now" and assert the expiry boundary instead of
/// agreeing with the calendar of the machine that runs it.

@ProviderFor(opportunityFeed)
final opportunityFeedProvider = OpportunityFeedProvider._();

/// What the background engine found, newest first (#4154).
///
/// A plain synchronous read: [OpportunityFeedStore] reads one Hive row
/// that is already open in this isolate, so there is no future to await
/// and no loading state to render. The background scan writes it; this
/// only ever reads.
///
/// **Expired entries are filtered out, not hidden.** An opportunity
/// carries an `expiresAt` because a price is not an opportunity forever,
/// and a feed that kept showing yesterday's bargain would teach the user
/// that the list is stale — the same failure a late notification causes
/// (#4149). They stay in the store until retention drops them; they just
/// stop being presented as current.
///
/// The clock comes through [appClockProvider] (#3660) rather than raw,
/// so a test can pin "now" and assert the expiry boundary instead of
/// agreeing with the calendar of the machine that runs it.

final class OpportunityFeedProvider
    extends
        $FunctionalProvider<List<FeedEntry>, List<FeedEntry>, List<FeedEntry>>
    with $Provider<List<FeedEntry>> {
  /// What the background engine found, newest first (#4154).
  ///
  /// A plain synchronous read: [OpportunityFeedStore] reads one Hive row
  /// that is already open in this isolate, so there is no future to await
  /// and no loading state to render. The background scan writes it; this
  /// only ever reads.
  ///
  /// **Expired entries are filtered out, not hidden.** An opportunity
  /// carries an `expiresAt` because a price is not an opportunity forever,
  /// and a feed that kept showing yesterday's bargain would teach the user
  /// that the list is stale — the same failure a late notification causes
  /// (#4149). They stay in the store until retention drops them; they just
  /// stop being presented as current.
  ///
  /// The clock comes through [appClockProvider] (#3660) rather than raw,
  /// so a test can pin "now" and assert the expiry boundary instead of
  /// agreeing with the calendar of the machine that runs it.
  OpportunityFeedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'opportunityFeedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$opportunityFeedHash();

  @$internal
  @override
  $ProviderElement<List<FeedEntry>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<FeedEntry> create(Ref ref) {
    return opportunityFeed(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<FeedEntry> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<FeedEntry>>(value),
    );
  }
}

String _$opportunityFeedHash() => r'adeb25f20131b4b78f799fe6e1aacc2e1cb1c2aa';
