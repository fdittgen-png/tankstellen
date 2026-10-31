<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Tools · Add iOS TestFlight tester

[Workflow source](../../../.github/workflows/ios-testers.yml) · [CI usage](../CI_USAGE.md) · [All workflows](../../../.github/workflows/README.md)

Explicit dispatch sends tester invitations. resend can remove/recreate invitations; review email, role and groups first. Retained as a separate workflow because its side effect differs from building or reporting status.

| Property | Contract |
|---|---|
| Target | TestFlight testers |
| Action/status | invite/manage testers; Manual maintenance |
| Triggers | `workflow_dispatch` |
| Token permissions | contents: read |
| Concurrency | `ios-testers`; cancel running: `False` |

## Run deliberately

```bash
gh workflow run ios-testers.yml --ref master -f email=person@example.com
```

- `email`: Tester email(s) to enroll — a single address or a comma-separated list (an invite email is sent to each) (default: `fdittgen@gmail.com,florian.dittgen@trelleborg.com`).
- `groups`: Comma-separated beta group names. Empty = ALL external groups, or the internal group(s) when the app has no external group. (default: ``).
- `role`: ASC role granted when an INTERNAL tester must be invited as a user (scoped to this app only). Default DEVELOPER. (default: `DEVELOPER`).
- `resend`: Re-issue a FRESH invite to a tester who lost theirs (external: remove+re-add; internal: delete+recreate the pending ASC invitation). (default: `False`).
- `first_name`: Tester first name (optional) (default: ``).
- `last_name`: Tester last name (optional) (default: ``).

## Jobs

| Job | Runner or reusable workflow | Limit (minutes) |
|---|---|---|
| `add-tester` | `ubuntu-latest` | 15 |

## Artifacts and credentials

No downloadable build artifact; inspect the step summary and external destination described above.

Referenced configured secrets (required according to the chosen action): `APP_STORE_CONNECT_API_ISSUER_ID`, `APP_STORE_CONNECT_API_KEY_BASE64`, `APP_STORE_CONNECT_API_KEY_ID`.

## Recovery

Inspect the failed job and source identity before retrying. Fix deterministic failures on the feature branch. For an unchanged CI candidate, rerun the **entire workflow** once so plan and reports share the new attempt. For a publishing workflow, inspect the destination first: a failed final step does not prove that nothing was uploaded. GitHub concurrency permits at most one pending run per group; it is not a FIFO release queue.
