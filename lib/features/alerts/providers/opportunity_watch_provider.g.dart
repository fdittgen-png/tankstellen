// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'opportunity_watch_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The kinds of opportunity the user wants to hear about (#4154).
///
/// A synchronous read of one already-open Hive row, like
/// [opportunityFeedProvider]. Defaults to every kind: an upgrade that
/// silently stopped alerting would be the bug #4149 warns about.

@ProviderFor(OpportunityWatch)
final opportunityWatchProvider = OpportunityWatchProvider._();

/// The kinds of opportunity the user wants to hear about (#4154).
///
/// A synchronous read of one already-open Hive row, like
/// [opportunityFeedProvider]. Defaults to every kind: an upgrade that
/// silently stopped alerting would be the bug #4149 warns about.
final class OpportunityWatchProvider
    extends $NotifierProvider<OpportunityWatch, Set<OpportunityKind>> {
  /// The kinds of opportunity the user wants to hear about (#4154).
  ///
  /// A synchronous read of one already-open Hive row, like
  /// [opportunityFeedProvider]. Defaults to every kind: an upgrade that
  /// silently stopped alerting would be the bug #4149 warns about.
  OpportunityWatchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'opportunityWatchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$opportunityWatchHash();

  @$internal
  @override
  OpportunityWatch create() => OpportunityWatch();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<OpportunityKind> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<OpportunityKind>>(value),
    );
  }
}

String _$opportunityWatchHash() => r'6161e93b299ee91a8f5941387683aa4820150c2e';

/// The kinds of opportunity the user wants to hear about (#4154).
///
/// A synchronous read of one already-open Hive row, like
/// [opportunityFeedProvider]. Defaults to every kind: an upgrade that
/// silently stopped alerting would be the bug #4149 warns about.

abstract class _$OpportunityWatch extends $Notifier<Set<OpportunityKind>> {
  Set<OpportunityKind> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<OpportunityKind>, Set<OpportunityKind>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<OpportunityKind>, Set<OpportunityKind>>,
              Set<OpportunityKind>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
