import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logging/error_logger.dart';

/// Bridges Riverpod provider failures into the unified [errorLogger]
/// pipeline (#1104). The constructor still accepts a [ProviderContainer]
/// so existing callsites continue to compile, but the observer no
/// longer reads from it directly — `errorLogger.log` resolves the
/// recorder through the bound container under the hood.
final class RiverpodTraceObserver extends ProviderObserver {
  /// Constructor parameter is intentionally accepted-and-ignored to
  /// preserve the public signature; the unified logger holds the
  /// bound container.
  RiverpodTraceObserver(ProviderContainer _);

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    // Fire-and-forget: the observer's contract is synchronous. Dropping
    // the future is fine because `errorLogger.log` never throws.
    errorLogger.log(ErrorLayer.providers, error, stackTrace);
  }
}
