# ADR 0003: No Firebase or Google Play Services

**Status:** Accepted
**Date:** 2024-06-01

## Context

Firebase and Google Play Services (GMS) are the default choice for Android
analytics, crash reporting, push notifications, and authentication. However,
they introduce privacy trade-offs:

- Firebase sends telemetry to Google servers, requiring GDPR consent flows.
- GMS dependencies prevent the app from running on de-Googled devices
  (GrapheneOS, LineageOS without microG) and Huawei AppGallery.
- The project aims to be a privacy-respecting, open-source alternative to
  commercial fuel apps.

## Decision

**Do not add Firebase or Google Play Services as dependencies.** Use
privacy-compatible alternatives for each capability:

| Capability        | Alternative                              |
|-------------------|------------------------------------------|
| Auth              | Supabase anonymous auth                  |
| Crash reporting   | TraceRecorder (local) + optional Sentry  |
| Push notifications| flutter_local_notifications (local only) |
| Analytics         | None (privacy by design)                 |
| Maps              | flutter_map + OpenStreetMap tiles         |

## Consequences

- **Privacy**: No user data leaves the device without explicit opt-in
  (TankSync). Simplifies GDPR compliance.
- **Broader device support**: Works on de-Googled Android and could target
  F-Droid in the future.
- **Missing features**: No server-side push, no A/B testing, no remote
  config. Acceptable for a solo-developer open-source project.
- **Supabase dependency**: Cloud features depend on Supabase instead, which
  is self-hostable and open-source.

## Alternatives Considered

- **Firebase with consent gate**: Would enable richer analytics but adds
  complexity and conflicts with the privacy-first brand.
- **Plausible/Matomo for analytics**: Considered for future use but not
  needed at current scale.
