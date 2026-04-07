import 'package:flutter/foundation.dart';

import 'background_price_fetcher.dart';

/// iOS stub implementation of [BackgroundPriceFetcher].
///
/// This is a no-op placeholder for future iOS WidgetKit background refresh.
/// When iOS support is implemented, this will be replaced with a real
/// implementation that uses BGTaskScheduler / WidgetKit timeline reloads.
class IosBackgroundPriceFetcherStub implements BackgroundPriceFetcher {
  @override
  Future<void> init() async {
    debugPrint('BackgroundPriceFetcher: iOS background refresh not yet implemented');
  }

  @override
  Future<void> cancelAll() async {
    // No-op: nothing to cancel on iOS stub.
  }
}
