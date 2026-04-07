# ADR 0004: Hive for local storage

**Status:** Accepted
**Date:** 2024-06-01

## Context

The app needs fast, persistent local storage for cached API responses,
user favorites, settings, and price history. Requirements:

- No native dependencies (pure Dart preferred for simpler builds).
- Key-value access pattern (most data is looked up by station ID or cache
  key, not queried with SQL joins).
- Fast reads for startup performance (< 500ms to show cached data).
- Works in isolates for background tasks (WorkManager).

## Decision

Use **Hive 2.x** as the primary local storage engine. All caching goes
through `CacheManager`, which wraps Hive with TTL logic and consistent
key formatting. Direct `HiveStorage.cacheData()` calls are prohibited.

Storage is split into named boxes:
- `cache` for API response caching with TTL metadata.
- `favorites` for user-saved stations.
- `settings` for user preferences.
- `price_history` for 30-day local price recording.

## Consequences

- **Performance**: Hive is one of the fastest Dart-native storage solutions;
  cold reads complete in single-digit milliseconds.
- **No SQL**: Complex queries (e.g., "cheapest station within 10 km last
  week") require manual filtering in Dart rather than SQL WHERE clauses.
- **Isolate compatibility**: Hive boxes can be opened independently in
  WorkManager isolates without shared state issues.
- **Migration burden**: Schema changes require manual migration logic since
  Hive has no built-in migration system.
- **Hive maintenance**: The original Hive package is in maintenance mode;
  may need to evaluate `isar` or `hive_ce` if bugs arise.

## Alternatives Considered

- **SharedPreferences**: Too limited for structured data; no support for
  lists or nested objects.
- **SQLite (sqflite/drift)**: More powerful queries but heavier setup,
  native dependencies, and overkill for key-value patterns.
- **Isar**: Promising successor to Hive but was less mature at decision
  time; may revisit.
