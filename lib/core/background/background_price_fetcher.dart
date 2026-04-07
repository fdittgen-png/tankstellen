/// Platform-agnostic interface for background price fetching.
///
/// Android uses WorkManager for periodic background tasks.
/// iOS will use WidgetKit background refresh (future implementation).
///
/// This abstraction allows platform-specific implementations without
/// duplicating the registration/scheduling logic across platforms.
abstract class BackgroundPriceFetcher {
  /// Initialize the background task scheduler and register periodic tasks.
  ///
  /// On Android, this initializes WorkManager and registers two periodic tasks:
  /// - Standard task (every 1h, requires battery not low)
  /// - Charging task (every 30min, requires device charging)
  ///
  /// On iOS, this will register WidgetKit background refresh (not yet implemented).
  Future<void> init();

  /// Cancel all registered background tasks.
  ///
  /// Called when the user disables background price refresh in settings,
  /// or during cleanup.
  Future<void> cancelAll();
}
