// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_moderation_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The authors (TankSync user ids) blocked on this device.

@ProviderFor(BlockedContentAuthors)
final blockedContentAuthorsProvider = BlockedContentAuthorsProvider._();

/// The authors (TankSync user ids) blocked on this device.
final class BlockedContentAuthorsProvider
    extends $NotifierProvider<BlockedContentAuthors, Set<String>> {
  /// The authors (TankSync user ids) blocked on this device.
  BlockedContentAuthorsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'blockedContentAuthorsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$blockedContentAuthorsHash();

  @$internal
  @override
  BlockedContentAuthors create() => BlockedContentAuthors();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$blockedContentAuthorsHash() =>
    r'3b4ef5f6e3b0f2d691a098c282e2cda91382f77f';

/// The authors (TankSync user ids) blocked on this device.

abstract class _$BlockedContentAuthors extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// The content target ids the viewer reported (and therefore hides).

@ProviderFor(ReportedContentTargets)
final reportedContentTargetsProvider = ReportedContentTargetsProvider._();

/// The content target ids the viewer reported (and therefore hides).
final class ReportedContentTargetsProvider
    extends $NotifierProvider<ReportedContentTargets, Set<String>> {
  /// The content target ids the viewer reported (and therefore hides).
  ReportedContentTargetsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reportedContentTargetsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reportedContentTargetsHash();

  @$internal
  @override
  ReportedContentTargets create() => ReportedContentTargets();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$reportedContentTargetsHash() =>
    r'f9cb8125cb4d1009b5210d33b5b1333244d5c215';

/// The content target ids the viewer reported (and therefore hides).

abstract class _$ReportedContentTargets extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Production submitter: writes one `content_reports` row via
/// [ContentReportsSync.submit]. Returns whether the row reached the
/// server so the UI can confirm honestly.

@ProviderFor(contentReportSubmit)
final contentReportSubmitProvider = ContentReportSubmitProvider._();

/// Production submitter: writes one `content_reports` row via
/// [ContentReportsSync.submit]. Returns whether the row reached the
/// server so the UI can confirm honestly.

final class ContentReportSubmitProvider
    extends
        $FunctionalProvider<
          ContentReportSubmit,
          ContentReportSubmit,
          ContentReportSubmit
        >
    with $Provider<ContentReportSubmit> {
  /// Production submitter: writes one `content_reports` row via
  /// [ContentReportsSync.submit]. Returns whether the row reached the
  /// server so the UI can confirm honestly.
  ContentReportSubmitProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contentReportSubmitProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contentReportSubmitHash();

  @$internal
  @override
  $ProviderElement<ContentReportSubmit> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ContentReportSubmit create(Ref ref) {
    return contentReportSubmit(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContentReportSubmit value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ContentReportSubmit>(value),
    );
  }
}

String _$contentReportSubmitHash() =>
    r'9aeb9e068a008f21860cab1706635f643e8c1e54';
