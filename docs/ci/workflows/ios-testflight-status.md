<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Status · iOS TestFlight

[Workflow source](../../../.github/workflows/ios-testflight-status.yml) · [CI usage](../CI_USAGE.md) · [All workflows](../../../.github/workflows/README.md)

Reports build processing/review/distribution and optionally a tester email. Use it to establish actual install eligibility after a build. It never starts another build or sends an invitation.

| Property | Contract |
|---|---|
| Target | TestFlight/testers |
| Action/status | read status; Read-only report |
| Triggers | `workflow_dispatch` |
| Token permissions | contents: read |
| Concurrency | `ios-testflight-status`; cancel running: `False` |

## Run deliberately

```bash
gh workflow run ios-testflight-status.yml --ref master
```

- `limit`: How many recent builds to report (newest first) (default: `15`).
- `tester`: Optional tester email to look up (state + group membership) (default: ``).

## Jobs

| Job | Runner or reusable workflow | Limit (minutes) |
|---|---|---|
| `status` | `ubuntu-latest` | 15 |

## Artifacts and credentials

No downloadable build artifact; inspect the step summary and external destination described above.

Referenced configured secrets (required according to the chosen action): `APP_STORE_CONNECT_API_ISSUER_ID`, `APP_STORE_CONNECT_API_KEY_BASE64`, `APP_STORE_CONNECT_API_KEY_ID`.

## Recovery

Inspect the failed job and source identity before retrying. Fix deterministic failures on the feature branch. For an unchanged CI candidate, rerun the **entire workflow** once so plan and reports share the new attempt. For a publishing workflow, inspect the destination first: a failed final step does not prove that nothing was uploaded. GitHub concurrency permits at most one pending run per group; it is not a FIFO release queue.
