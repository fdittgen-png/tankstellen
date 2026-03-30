import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../trace_recorder.dart';

final class RiverpodTraceObserver extends ProviderObserver {
  final ProviderContainer _container;
  RiverpodTraceObserver(this._container);

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    _container.read(traceRecorderProvider).record(error, stackTrace);
  }
}
