# Self-Hosted Telemetry (Glitchtip)

> Status: opt-in. Sentry is the default. Swap procedure is documented
> below and exercised by `test/core/telemetry/glitchtip_compatibility_test.dart`.

## Why

Tankstellen's privacy-first leitmotiv says the user owns their data.
Crash and performance telemetry are no exception: even with PII
scrubbing (see `lib/core/telemetry/pii_scrubber.dart`) the operator
ultimately decides which third party sees the scrubbed events.

Sentry's free tier is generous and SaaS-managed, but the strongest
privacy posture is one where **the events never leave a server you
control**. Glitchtip exists for exactly that case.

## What is Glitchtip

[Glitchtip](https://glitchtip.com/) is an OSS error-monitoring backend
that re-implements the Sentry ingest API (envelope endpoint) on top of
Django + Postgres. The Sentry SDK doesn't know or care that it's
talking to Glitchtip — it sees a DSN, it POSTs envelopes, it gets a
200 back. Drop-in replacement.

Practically that means:

- **No code change in this app.** The `core/telemetry/` abstraction
  and `SentryFlutter.init` in `lib/app/app_initializer.dart` already
  treat the DSN as an opaque string. Point the DSN at a Glitchtip
  endpoint and events flow there instead.
- **Same SDK features used by this app keep working** — exception
  capture, breadcrumbs, releases, environments, `beforeSend` PII
  scrubbing. Glitchtip implements all of these.
- **Some Sentry-only features are not implemented** — see Trade-offs
  below.

## Self-hosting

Glitchtip publishes a canonical `docker-compose.yml` at
<https://glitchtip.com/documentation/install>. The version below is
the **shape** of a minimal production install; always cross-check the
upstream docs for the latest images and required env vars before you
deploy.

```yaml
# docker-compose.yml — minimal, single-VPS deployment.
# Authoritative version: https://glitchtip.com/documentation/install
services:
  postgres:
    image: postgres:16
    restart: unless-stopped
    environment:
      POSTGRES_DB: glitchtip
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - pgdata:/var/lib/postgresql/data

  redis:
    image: redis
    restart: unless-stopped

  web:
    image: glitchtip/glitchtip
    depends_on: [postgres, redis]
    ports:
      - "8000:8000"
    environment:
      DATABASE_URL: postgres://postgres:${POSTGRES_PASSWORD}@postgres:5432/glitchtip
      SECRET_KEY: ${SECRET_KEY}
      PORT: 8000
      EMAIL_URL: consolemail://
      GLITCHTIP_DOMAIN: https://telemetry.example.org
      DEFAULT_FROM_EMAIL: telemetry@example.org
      CELERY_WORKER_AUTOSCALE: "1,3"
    restart: unless-stopped

  worker:
    image: glitchtip/glitchtip
    command: ./bin/run-celery-with-beat.sh
    depends_on: [postgres, redis]
    environment:
      DATABASE_URL: postgres://postgres:${POSTGRES_PASSWORD}@postgres:5432/glitchtip
      SECRET_KEY: ${SECRET_KEY}
    restart: unless-stopped

volumes:
  pgdata:
```

### Sizing

A €5/month single-core, 1 GB RAM VPS (Hetzner CX11, Scaleway STARDUST1-S,
DigitalOcean basic, OVH Eco) handles a small alpha-tester crowd
comfortably. Scale up to 2 GB RAM before opening to public traffic —
the Celery worker and Postgres both want headroom under burst.

### Persistence

The `pgdata` named volume above is the only stateful piece. **Back it
up.** Losing the Postgres volume loses every recorded event. A nightly
`pg_dump` to off-host storage is enough.

### Reverse proxy

Front the `web` container with Caddy, nginx, or Traefik to terminate
TLS and provide the `https://telemetry.example.org` Glitchtip needs.
The DSN you hand to the app must use HTTPS.

## Swap procedure

The app reads its DSN from one of two places, in this order
(see `AppInitializer.resolveSentryDsn` in `lib/app/app_initializer.dart`):

1. **`sentry_dsn` Hive setting** — manually entered via
   *Settings → Diagnostics* on a single device. Wins if non-empty.
2. **`SENTRY_DSN` dart-define** — compile-time, applies to every
   build of the resulting binary.

To swap the entire fleet to Glitchtip, change the dart-define at
build time:

```bash
flutter build apk --release \
  --dart-define=SENTRY_DSN=https://<publicKey>@telemetry.example.org/<projectId>
```

To swap a single dev device to Glitchtip, paste the same DSN into
*Settings → Diagnostics → Sentry DSN* and restart the app.

That's it. **No code change. No new dependency. No rebuild flag
beyond the DSN value.** The dart-define key stays `SENTRY_DSN`
regardless of backend — the issue's acceptance criterion
("config-only swap") is exactly this property and is pinned by
`test/core/telemetry/glitchtip_compatibility_test.dart`.

## Verification

Three checks confirm events are landing on your Glitchtip instance:

1. **App startup log** — when `consent_error_reporting` is true and
   the DSN is non-empty, `SentryFlutter.init` runs in
   `AppInitializer.run`. A failure to reach the endpoint shows up as
   a Dio/HTTP error in `flutter logs`.
2. **Glitchtip UI** — open `https://telemetry.example.org`, navigate
   to your project, and watch *Issues*. The first uncaught exception
   the app hits should appear within ~30 seconds (Celery flush
   interval).
3. **Manual test exception** — temporarily wire a button to
   `errorLogger.log('manual', Exception('Glitchtip swap test'),
   StackTrace.current)`. The single event lets you confirm scrubbing,
   release tagging, and breadcrumb capture all work end-to-end.
   Remove the button before merge.

## Trade-offs

Glitchtip implements the **error-monitoring** subset of the Sentry
API. Features not implemented (or implemented partially) at the time
of writing:

| Feature | Sentry | Glitchtip |
|--------|--------|-----------|
| Exception + breadcrumb capture | yes | yes |
| Releases + environments | yes | yes |
| `beforeSend` / PII scrubbing | yes | yes (same SDK hook) |
| Source maps for web/JS | yes | partial |
| **Performance monitoring (transactions/spans)** | yes | **no** |
| **Profiling** | yes | **no** |
| Session replay | yes | no |
| User feedback widget | yes | partial |
| Native crash symbolication (Android NDK / iOS dSYM) | yes | partial |

This app currently sets `tracesSampleRate = 0.2`. On Glitchtip those
transaction events are silently dropped. If your operator workflow
relies on Sentry's performance tab, stay on Sentry.

For everything we use today — uncaught exceptions, breadcrumbs from
Dio/Riverpod/navigation, releases tied to `pubspec` version, scrubbed
`beforeSend` payloads — Glitchtip is a one-line config swap and a
€5/month VPS away.
