<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Tools · iOS beta review info

[Workflow source](../../../.github/workflows/ios-beta-review.yml) · [CI usage](../CI_USAGE.md) · [All workflows](../../../.github/workflows/README.md)

Updates Beta App Review information. Contact inputs override existing secret/default values. This changes App Store Connect configuration but does not build or submit the app.

| Property | Contract |
|---|---|
| Target | TestFlight review configuration |
| Action/status | update review info; Manual maintenance |
| Triggers | `workflow_dispatch` |
| Token permissions | contents: read |
| Concurrency | `ios-beta-review`; cancel running: `False` |

## Run deliberately

```bash
gh workflow run ios-beta-review.yml --ref master
```

- `contact_first`: App-Review contact first name (optional — overrides BETA_CONTACT_FIRST secret / Florian default) (default: ``).
- `contact_last`: App-Review contact last name (optional — overrides BETA_CONTACT_LAST secret / Dittgen default) (default: ``).

## Jobs

| Job | Runner or reusable workflow | Limit (minutes) |
|---|---|---|
| `configure-beta-review` | `ubuntu-latest` | 15 |

## Artifacts and credentials

No downloadable build artifact; inspect the step summary and external destination described above.

Referenced configured secrets (required according to the chosen action): `APP_STORE_CONNECT_API_ISSUER_ID`, `APP_STORE_CONNECT_API_KEY_BASE64`, `APP_STORE_CONNECT_API_KEY_ID`, `BETA_CONTACT_FIRST`, `BETA_CONTACT_LAST`, `BETA_CONTACT_PHONE`, `DEMO_VIDEO_URL`.

## Recovery

Inspect the failed job and source identity before retrying. Fix deterministic failures on the feature branch. For an unchanged CI candidate, rerun the **entire workflow** once so plan and reports share the new attempt. For a publishing workflow, inspect the destination first: a failed final step does not prove that nothing was uploaded. GitHub concurrency permits at most one pending run per group; it is not a FIFO release queue.
