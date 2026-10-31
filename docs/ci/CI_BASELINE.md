<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# CI timing baseline

Read from the Actions API on 2026-10-31. These are **three individual historical
samples**, not a distribution or matched before/after experiment. No hosted
speedup is claimed for the refactor. Queue-to-first-job is reported separately;
job durations include setup and teardown, not just test execution.

| Case | Event / source | Run link | Queue to first job | Observed execution |
|---|---|---|---|---|
| PR | `pull_request`, `c829025b4d4736f42a10ffc24d2970f8ae856684` | [41215436249](https://github.com/fdittgen-png/tankstellen/actions/runs/41215436249) | 3 s (15:33:41 → 15:33:44 UTC) | Last required test shard finished 16:02:05; advisory coverage finished 16:02:52. Four test jobs: 24m51s–28m07s; their summed runner time 104m45s. |
| Master full pass | `push`, `3e2bd9330a6c7c52131cb9e10f07958ae380bfa5` | [35553800100](https://github.com/fdittgen-png/tankstellen/actions/runs/35553800100) | 20 s (02:19:32 → 02:19:52 UTC) | Final coverage job finished 03:25:18 UTC. Four test jobs: 54m05s–64m09s; summed test runner time 241m33s. |
| F-Droid release audit | `push`, `13f2809838b6b947b931ef2a94faab9a0ea96a47` | [41217693416](https://github.com/fdittgen-png/tankstellen/actions/runs/41217693416) | 19 s (16:02:12 → 16:02:31 UTC) | `build-fdroid` 16:02:31 → 16:14:25 UTC, 11m54s. |

PR test durations, shard 0/1/2/3: 1687/1576/1491/1531 seconds.
Master test durations, shard 0/1/2/3: 3759/3640/3245/3849 seconds.
Cache state and exact selected-test counts are **unlabelled** in these sampled
metadata reads; do not infer warm-cache speed, coverage overhead or perfect
shard balance from them. The master sample is older than the PR sample and
must not be presented as a comparison of equal work.

Reproduce each read:

```bash
gh run view RUN_ID --repo fdittgen-png/tankstellen \
  --json url,event,headSha,createdAt,jobs
```

The new plan and shard artifacts retain exact selected files, plain/measured
allocations, commands, elapsed time, original process exits and per-test/file
timing observations from the same invocation. Use a matched candidate and
configuration to compare wall time, queue time and total runner time. Label
cache hits from actual setup logs; run metadata alone cannot establish them.

Structural changes to measure: one selector/coverage graph instead of four,
no previous-green verdict reuse, no duplicate docs check producer, no build
state caches, one dependency-cache owner, no signed packaging on every master
push, and a path-filtered advisory F-Droid build. Export-aware selection can
select more tests than the legacy CLI: that correctness cost is intentional.
The full-suite coverage cost remains and is the next measurement target.
