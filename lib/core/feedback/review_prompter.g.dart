// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_prompter.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Flavor-selected [ReviewPrompter]: the libre build gets the no-op, every
/// other build gets the real store prompter. Overridable in tests.

@ProviderFor(reviewPrompter)
final reviewPrompterProvider = ReviewPrompterProvider._();

/// Flavor-selected [ReviewPrompter]: the libre build gets the no-op, every
/// other build gets the real store prompter. Overridable in tests.

final class ReviewPrompterProvider
    extends $FunctionalProvider<ReviewPrompter, ReviewPrompter, ReviewPrompter>
    with $Provider<ReviewPrompter> {
  /// Flavor-selected [ReviewPrompter]: the libre build gets the no-op, every
  /// other build gets the real store prompter. Overridable in tests.
  ReviewPrompterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reviewPrompterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reviewPrompterHash();

  @$internal
  @override
  $ProviderElement<ReviewPrompter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ReviewPrompter create(Ref ref) {
    return reviewPrompter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReviewPrompter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReviewPrompter>(value),
    );
  }
}

String _$reviewPrompterHash() => r'6223e9edcd438f576d12ef681d9cb2a7c90b8ac6';
