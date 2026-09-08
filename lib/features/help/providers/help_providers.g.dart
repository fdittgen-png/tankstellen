// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'help_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The guide text. Kept alive: it is a third of a megabyte of markdown
/// that never changes between releases, and re-reading it on every push
/// of `/help` is a visible stutter.

@ProviderFor(helpDocument)
final helpDocumentProvider = HelpDocumentFamily._();

/// The guide text. Kept alive: it is a third of a megabyte of markdown
/// that never changes between releases, and re-reading it on every push
/// of `/help` is a visible stutter.

final class HelpDocumentProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// The guide text. Kept alive: it is a third of a megabyte of markdown
  /// that never changes between releases, and re-reading it on every push
  /// of `/help` is a visible stutter.
  HelpDocumentProvider._({
    required HelpDocumentFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'helpDocumentProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$helpDocumentHash();

  @override
  String toString() {
    return r'helpDocumentProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    final argument = this.argument as String;
    return helpDocument(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is HelpDocumentProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$helpDocumentHash() => r'0e26896814ee134c257450112ccabaae4e92ec7b';

/// The guide text. Kept alive: it is a third of a megabyte of markdown
/// that never changes between releases, and re-reading it on every push
/// of `/help` is a visible stutter.

final class HelpDocumentFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String>, String> {
  HelpDocumentFamily._()
    : super(
        retry: null,
        name: r'helpDocumentProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// The guide text. Kept alive: it is a third of a megabyte of markdown
  /// that never changes between releases, and re-reading it on every push
  /// of `/help` is a visible stutter.

  HelpDocumentProvider call(String languageCode) =>
      HelpDocumentProvider._(argument: languageCode, from: this);

  @override
  String toString() => r'helpDocumentProvider';
}

/// The anchor map. Error-tolerant on purpose: a missing or malformed
/// map costs the reader an exact jump, not the guide — so it answers
/// with an empty map rather than an error screen.

@ProviderFor(helpAnchors)
final helpAnchorsProvider = HelpAnchorsFamily._();

/// The anchor map. Error-tolerant on purpose: a missing or malformed
/// map costs the reader an exact jump, not the guide — so it answers
/// with an empty map rather than an error screen.

final class HelpAnchorsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, String>>,
          Map<String, String>,
          FutureOr<Map<String, String>>
        >
    with
        $FutureModifier<Map<String, String>>,
        $FutureProvider<Map<String, String>> {
  /// The anchor map. Error-tolerant on purpose: a missing or malformed
  /// map costs the reader an exact jump, not the guide — so it answers
  /// with an empty map rather than an error screen.
  HelpAnchorsProvider._({
    required HelpAnchorsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'helpAnchorsProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$helpAnchorsHash();

  @override
  String toString() {
    return r'helpAnchorsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Map<String, String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, String>> create(Ref ref) {
    final argument = this.argument as String;
    return helpAnchors(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is HelpAnchorsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$helpAnchorsHash() => r'b6a9a7b2383b681b01c6a926d3fd8a425f7a2c31';

/// The anchor map. Error-tolerant on purpose: a missing or malformed
/// map costs the reader an exact jump, not the guide — so it answers
/// with an empty map rather than an error screen.

final class HelpAnchorsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Map<String, String>>, String> {
  HelpAnchorsFamily._()
    : super(
        retry: null,
        name: r'helpAnchorsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// The anchor map. Error-tolerant on purpose: a missing or malformed
  /// map costs the reader an exact jump, not the guide — so it answers
  /// with an empty map rather than an error screen.

  HelpAnchorsProvider call(String languageCode) =>
      HelpAnchorsProvider._(argument: languageCode, from: this);

  @override
  String toString() => r'helpAnchorsProvider';
}
