<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# CI · iOS simulator build

[Workflow source](../../../.github/workflows/ios-validate.yml) · [CI usage](../CI_USAGE.md) · [All workflows](../../../.github/workflows/README.md)

Unsigned simulator compilation for native iOS/dependency changes. Dispatch on a feature branch to validate Dart-only changes before paying for TestFlight. No signing keys or store access. Simulator output is not a device IPA or proof of successful App Review.

| Property | Contract |
|---|---|
| Target | iOS simulator |
| Action/status | build; Advisory |
| Triggers | `pull_request` (path filtered); `workflow_dispatch` |
| Token permissions | contents: read |
| Concurrency | `ios-validate-${{ github.event_name }}-${{ github.event.pull_request.number || github.ref }}`; cancel running: `${{ github.event_name == 'pull_request' }}` |

## Run deliberately

```bash
gh workflow run ios-validate.yml --ref YOUR_BRANCH
```

No inputs.

## Jobs

| Job | Runner or reusable workflow | Limit (minutes) |
|---|---|---|
| `ios-simulator` | `macos-15` | 45 |

## Artifacts and credentials

- `ios-simulator-attempt-${{ github.run_attempt }}`: `${{ runner.temp }}/ios-simulator.zip`.

Referenced configured secrets (required according to the chosen action): none beyond the scoped GitHub token.

## Recovery

Inspect the failed job and source identity before retrying. Fix deterministic failures on the feature branch. For an unchanged CI candidate, rerun the **entire workflow** once so plan and reports share the new attempt. For a publishing workflow, inspect the destination first: a failed final step does not prove that nothing was uploaded. GitHub concurrency permits at most one pending run per group; it is not a FIFO release queue.
