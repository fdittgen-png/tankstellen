import '../error/exceptions.dart';
import '../services/service_result.dart';
import 'result.dart';

/// Bridges the existing [ServiceResult] / exception pattern with [Result].
///
/// Wraps an async call that returns [ServiceResult<T>] and may throw
/// [ServiceChainExhaustedException] into a [Result] that is either:
///
///   - [Success] containing the [ServiceResult<T>] (with its metadata)
///   - [Failure] containing a [ServiceFailure] (with accumulated errors)
///
/// This enables callers to pattern-match instead of try/catch:
///
/// ```dart
/// final result = await captureServiceResult(
///   () => service.searchStations(params),
/// );
/// switch (result) {
///   case Success(:final value):
///     showStations(value.data);
///   case Failure(:final error):
///     showError(error.message);
/// }
/// ```
Future<Result<ServiceResult<T>, ServiceFailure>> captureServiceResult<T>(
  Future<ServiceResult<T>> Function() call,
) async {
  try {
    return Success(await call());
  } on ServiceChainExhaustedException catch (e) {
    return Failure(ServiceFailure(
      message: e.message,
      errors: e.errors.cast<ServiceError>(),
    ));
  }
}

/// Structured error returned when every fallback in a service chain fails.
///
/// Carries the same accumulated [ServiceError] list as
/// [ServiceChainExhaustedException] but as a value instead of an exception.
class ServiceFailure {
  final String message;
  final List<ServiceError> errors;

  const ServiceFailure({
    required this.message,
    this.errors = const [],
  });

  @override
  String toString() => 'ServiceFailure: $message';
}
