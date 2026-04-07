# ADR 0002: Local-first architecture

**Status:** Accepted
**Date:** 2024-06-01

## Context

Users frequently check fuel prices while driving, often in areas with poor
mobile connectivity (rural France, mountain tunnels, border regions). The app
must remain useful when the network is unreliable or completely unavailable.

A server-first approach would block the UI on network requests, leading to
empty screens and frustrated users. A local-first approach stores data on
the device and treats the network as an optimization rather than a
requirement.

## Decision

Adopt a **local-first data strategy**: save data locally before syncing to
the server, load from the local database on startup, and let local state win
on conflicts. The optional TankSync cloud backend enriches the experience
but is never required for core functionality.

Key rules:
- Save locally first, then sync to server.
- Load from DB, then overwrite with local (local always wins on conflict).
- Sync adds/changes but never deletes; only explicit user actions trigger
  server-side deletes.
- Background tasks (WorkManager) run independently in isolates using
  Dio/Hive directly, without Riverpod.

## Consequences

- **Offline resilience**: The app shows cached prices and favorites even
  without connectivity.
- **Conflict resolution simplicity**: Local-wins policy avoids complex merge
  logic at the cost of occasionally losing server-side changes.
- **Stale data risk**: Users may see outdated prices; mitigated by freshness
  badges and `isStale` flags on every `ServiceResult`.
- **Duplicate storage**: Some data exists in both Hive and Supabase,
  increasing storage footprint slightly.

## Alternatives Considered

- **Server-first (API-only)**: Simpler data flow but unusable offline; ruled
  out given the driving use case.
- **CRDT-based sync**: Elegant conflict resolution but over-engineered for
  the current feature set; may revisit for collaborative features.
- **SQLite + drift**: Considered for structured queries, but Hive's NoSQL
  model was simpler for key-value caching patterns.
