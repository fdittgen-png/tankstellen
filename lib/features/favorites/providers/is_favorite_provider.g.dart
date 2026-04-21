// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'is_favorite_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether a specific station is favorited (checks both fuel and EV).

@ProviderFor(isFavorite)
final isFavoriteProvider = IsFavoriteFamily._();

/// Whether a specific station is favorited (checks both fuel and EV).

final class IsFavoriteProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether a specific station is favorited (checks both fuel and EV).
  IsFavoriteProvider._({
    required IsFavoriteFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isFavoriteProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isFavoriteHash();

  @override
  String toString() {
    return r'isFavoriteProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as String;
    return isFavorite(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IsFavoriteProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isFavoriteHash() => r'407f8aa58c4a51cd73bb614574835fabbf173b80';

/// Whether a specific station is favorited (checks both fuel and EV).

final class IsFavoriteFamily extends $Family
    with $FunctionalFamilyOverride<bool, String> {
  IsFavoriteFamily._()
    : super(
        retry: null,
        name: r'isFavoriteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether a specific station is favorited (checks both fuel and EV).

  IsFavoriteProvider call(String stationId) =>
      IsFavoriteProvider._(argument: stationId, from: this);

  @override
  String toString() => r'isFavoriteProvider';
}

/// Whether a specific EV station is favorited (backward compatibility alias).

@ProviderFor(isEvFavorite)
final isEvFavoriteProvider = IsEvFavoriteFamily._();

/// Whether a specific EV station is favorited (backward compatibility alias).

final class IsEvFavoriteProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether a specific EV station is favorited (backward compatibility alias).
  IsEvFavoriteProvider._({
    required IsEvFavoriteFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isEvFavoriteProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isEvFavoriteHash();

  @override
  String toString() {
    return r'isEvFavoriteProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as String;
    return isEvFavorite(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IsEvFavoriteProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isEvFavoriteHash() => r'acd73588a221554915fd24b7637376e73cfacdc8';

/// Whether a specific EV station is favorited (backward compatibility alias).

final class IsEvFavoriteFamily extends $Family
    with $FunctionalFamilyOverride<bool, String> {
  IsEvFavoriteFamily._()
    : super(
        retry: null,
        name: r'isEvFavoriteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether a specific EV station is favorited (backward compatibility alias).

  IsEvFavoriteProvider call(String stationId) =>
      IsEvFavoriteProvider._(argument: stationId, from: this);

  @override
  String toString() => r'isEvFavoriteProvider';
}
