# TankSync -- Supabase Backend

Optional cloud backend for the Tankstellen fuel price app.
The app works 100% offline/locally without this. TankSync adds:

- Cross-device favorite sync
- Server-side price alerts with push notifications (via ntfy.sh)
- Price history charts
- Community price reports

## Prerequisites

- [Supabase CLI](https://supabase.com/docs/guides/cli) installed
- A Supabase project (free tier works fine): https://supabase.com/dashboard

## Setup

### 1. Create a Supabase project

Go to https://supabase.com/dashboard and create a new project.
Note your project URL and anon key from Settings > API.

### 2. Link to your project

```bash
supabase login
supabase link --project-ref YOUR_PROJECT_REF
```

### 3. Run migrations

```bash
supabase db push
```

This applies all migrations in `migrations/` in order:
1. `20260327000001_initial_schema.sql` -- Tables
2. `20260327000002_rls_policies.sql` -- Row Level Security
3. `20260327000003_indexes.sql` -- Performance indexes

### 4. (Optional) Seed development data

```bash
supabase db reset
```

This resets the database and applies migrations + `seed.sql`.

## Local Development

Start a local Supabase instance:

```bash
supabase start
```

Local endpoints:
- API: http://localhost:54321
- Studio: http://localhost:54323
- DB: postgresql://postgres:postgres@localhost:54322/postgres

## Environment Variables

The Flutter app needs these to connect:

| Variable | Description | Where to find |
|----------|-------------|---------------|
| `SUPABASE_URL` | Project API URL | Dashboard > Settings > API |
| `SUPABASE_ANON_KEY` | Public anon key | Dashboard > Settings > API |

Users enter these in the app settings screen. They are stored locally
on device via Hive -- never hardcoded in source (privacy constraint).

## Database Schema

### Tables

| Table | Purpose | RLS |
|-------|---------|-----|
| `users` | Anonymous user accounts (UUID only) | Own record only |
| `favorites` | Synced favorite stations | Own data only |
| `alerts` | Price alert configurations | Own data only |
| `price_snapshots` | Historical prices for alert evaluation | Read: all, Write: service_role |
| `price_reports` | Community price corrections | Read: all, Write: own |
| `push_tokens` | ntfy.sh notification topics | Own data only |
| `sync_settings` | Per-user sync preferences | Own data only |

### Security

- Row Level Security (RLS) is enabled on ALL tables
- Users can only access their own data (enforced at database level)
- Price snapshots are read-only for users; only Edge Functions (service_role) can write
- Community price reports are readable by all, writable by the reporter
- No email or personal data is stored -- users are anonymous UUIDs

## Edge Functions

Deploy Edge Functions for server-side tasks:

```bash
supabase functions deploy price-checker
supabase functions deploy alert-evaluator
```

These are defined in `supabase/functions/` (created separately).

## Maintenance

### Price snapshot cleanup

Price snapshots older than 90 days should be cleaned up periodically.
Use pg_cron or a scheduled Edge Function:

```sql
DELETE FROM public.price_snapshots
WHERE recorded_at < now() - interval '90 days';
```
