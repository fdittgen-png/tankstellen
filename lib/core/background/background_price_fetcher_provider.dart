import 'dart:io';

import 'android_background_price_fetcher.dart';
import 'background_price_fetcher.dart';
import 'ios_background_price_fetcher_stub.dart';

/// Creates the platform-appropriate [BackgroundPriceFetcher] implementation.
///
/// - Android: [AndroidBackgroundPriceFetcher] (WorkManager-based)
/// - iOS: [IosBackgroundPriceFetcherStub] (no-op placeholder)
/// - Other platforms: [IosBackgroundPriceFetcherStub] (safe no-op fallback)
BackgroundPriceFetcher createBackgroundPriceFetcher() {
  if (Platform.isAndroid) {
    return AndroidBackgroundPriceFetcher();
  }
  // iOS and other platforms get the stub for now.
  return IosBackgroundPriceFetcherStub();
}
