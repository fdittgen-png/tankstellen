# ADR 0005: Service chain fallback pattern

**Status:** Accepted
**Date:** 2024-08-01

## Context

The app integrates with 11 country-specific fuel price APIs, each with
different reliability characteristics, rate limits, and response formats.
Network failures, API outages, and rate limiting are common. Users expect
the app to show *something* rather than an error screen.

A naive approach (call API, show result or error) leads to frequent blank
screens. The app needs a resilient data-fetching strategy that gracefully
degrades when APIs are unavailable.

## Decision

Implement a **4-step service chain fallback pattern** for all external data:

1. **Fresh cache** -- Return immediately if cached data is within its TTL.
2. **API call** -- Fetch from the remote API; on success, cache the result.
3. **Stale cache** -- If the API fails, return expired cached data with an
   `isStale` flag so the UI can show a freshness warning.
4. **Error** -- If no cached data exists, return a structured error with
   accumulated diagnostics from all fallback attempts.

Additional mechanisms:
- **Request coalescing**: An in-flight map prevents duplicate concurrent API
  calls for the same cache key.
- **`ServiceResult<T>`**: Every response carries source metadata, freshness
  info, and an error accumulator for the fallback chain.
- Rate limiting with jitter prevents thundering herd on API recovery.

## Consequences

- **High availability**: Users almost always see data, even if stale.
- **Transparency**: `freshnessLabel` and `isStale` flag inform users about
  data quality without hiding degradation.
- **Complexity**: Every service must be wrapped in `StationServiceChain`;
  new country APIs must follow the pattern.
- **Testing surface**: Each fallback step needs explicit test coverage
  (fresh hit, stale hit, miss, API error + stale, total failure).
- **Stale data risk**: Users may act on outdated prices; mitigated by
  visual freshness indicators.

## Alternatives Considered

- **Simple retry with exponential backoff**: Does not solve the "show
  something" problem when the API is down for extended periods.
- **Circuit breaker only**: Would prevent hammering failed APIs but still
  shows errors rather than stale data.
- **Offline-first with background sync**: More complex to implement; the
  chain pattern achieves similar UX with less infrastructure.
