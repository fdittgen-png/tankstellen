/// A type-safe union for operations that can succeed or fail.
///
/// Uses Dart sealed classes so callers can pattern-match exhaustively:
///
/// ```dart
/// final result = await fetchStations(params);
/// switch (result) {
///   case Success(:final value):
///     showStations(value);
///   case Failure(:final error):
///     showError(error);
/// }
/// ```
///
/// [T] is the success value type, [E] is the error type.
sealed class Result<T, E> {
  const Result();

  /// True when this is a [Success].
  bool get isSuccess => this is Success<T, E>;

  /// True when this is a [Failure].
  bool get isFailure => this is Failure<T, E>;

  /// Returns the success value or `null`.
  T? get valueOrNull => switch (this) {
        Success(:final value) => value,
        Failure() => null,
      };

  /// Returns the error or `null`.
  E? get errorOrNull => switch (this) {
        Success() => null,
        Failure(:final error) => error,
      };

  /// Returns the success value or throws [StateError].
  T get valueOrThrow => switch (this) {
        Success(:final value) => value,
        Failure(:final error) =>
          throw StateError('Result is Failure: $error'),
      };

  /// Transforms the success value, leaving failures untouched.
  Result<U, E> map<U>(U Function(T value) transform) => switch (this) {
        Success(:final value) => Success(transform(value)),
        Failure(:final error) => Failure(error),
      };

  /// Transforms the error value, leaving successes untouched.
  Result<T, F> mapError<F>(F Function(E error) transform) => switch (this) {
        Success(:final value) => Success(value),
        Failure(:final error) => Failure(transform(error)),
      };

  /// Transforms the success value with a function that itself returns
  /// a [Result], flattening the nested result.
  Result<U, E> flatMap<U>(Result<U, E> Function(T value) transform) =>
      switch (this) {
        Success(:final value) => transform(value),
        Failure(:final error) => Failure(error),
      };

  /// Collapses both cases into a single value.
  U fold<U>({
    required U Function(T value) onSuccess,
    required U Function(E error) onFailure,
  }) =>
      switch (this) {
        Success(:final value) => onSuccess(value),
        Failure(:final error) => onFailure(error),
      };

  /// Returns the success value or a computed fallback.
  T getOrElse(T Function(E error) fallback) => switch (this) {
        Success(:final value) => value,
        Failure(:final error) => fallback(error),
      };

  @override
  String toString() => switch (this) {
        Success(:final value) => 'Success($value)',
        Failure(:final error) => 'Failure($error)',
      };
}

/// The success variant of [Result].
final class Success<T, E> extends Result<T, E> {
  final T value;
  const Success(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T, E> && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// The failure variant of [Result].
final class Failure<T, E> extends Result<T, E> {
  final E error;
  const Failure(this.error);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T, E> && other.error == error;

  @override
  int get hashCode => error.hashCode;
}
