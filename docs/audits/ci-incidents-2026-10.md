<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# October 2026 CI incidents

Audit base: `f16377fe008184dbab55d8ef061cd5fd01b797b4`.

| Issues | Evidence | Resolution boundary |
|---|---|---|
| #4522, #4537, #4538, #4541 | Runs [39019423622](https://github.com/fdittgen-png/tankstellen/actions/runs/39019423622), [39933965949](https://github.com/fdittgen-png/tankstellen/actions/runs/39933965949), [40181152856](https://github.com/fdittgen-png/tankstellen/actions/runs/40181152856), [40309760399](https://github.com/fdittgen-png/tankstellen/actions/runs/40309760399) fail the two MIMIT CSV probes, Rome/Milan searches and Argentina CSV probe. Some continue reporting transport errors after the runner timeout. | This change bounds/cancels the probes and their retries. It does not establish upstream recovery. Keep the incidents open pending a genuine green current run. |
| #4536 | [39579800059](https://github.com/fdittgen-png/tankstellen/actions/runs/39579800059) is cancelled, with no failed-test log excerpt available. | Do not infer the same five failures or claim a fix. |
| #4518 | [37718691784](https://github.com/fdittgen-png/tankstellen/actions/runs/37718691784) uploads successfully; the installability guard reports `WAITING_FOR_BETA_REVIEW`. | The guard correctly fails. Track actual external availability in #3814 and the physical review demonstration in #3537; an upload is not approval. |
| #4559 | [41231406669](https://github.com/fdittgen-png/tankstellen/actions/runs/41231406669) completes archive/export, starts pilot upload at 19:10:43 UTC, then reports no upload completion before cancellation at 19:51:30 UTC. | An Apple upload stall, not a compiler failure. No successful upload or review is inferred. |

The endpoint canary #4535 independently reports MIMIT as unavailable and
documents Argentina's runner-network limitation. This patch neither skips
these tests nor converts failed probes to success. Network capability policy
and upstream recovery remain separate from test cancellation correctness.

The offline regressions in `test/helpers/network_deadline_test.dart` use a
fake clock: deadline cancellation, late source error consumption, cancellation
during retry backoff, wrapped cancellation, and success/failure cleanup.
`network_retry_test.dart` retains transient-retry, persistent-failure, HTTP 404,
assertion-failure and TLS-trust coverage. These are not live-service passes.

Validation with Flutter 3.44.9 / Dart 3.12.2:

```sh
flutter test --no-pub test/helpers/network_retry_test.dart test/helpers/network_deadline_test.dart test/core/services/api_connectivity_test.dart --name 'probe deadline|transient-error|networkTestSecurityContext|API Response Parsing' -r expanded
flutter analyze --no-pub
```

The selected run passes 13 tests; the analyzer reports zero issues. Removing
the cancellation checks from `retryNetwork` makes the two cancellation
regressions fail while the other three deadline/cleanup cases pass. The
fixed source is restored. All 163 lint cases pass. Clean build-runner and
the complete ARB/pseudo/localization pipeline produce no generated drift.
No live upstream recovery was tested or claimed.

After integrating the merged CI refactor, the same 13 offline regressions
pass again, the analyzer remains clean, and all 303 lint/localization contract
cases pass. Clean code generation writes 550 outputs with no committed drift;
the full ARB/pseudo/localization pipeline also leaves no generated drift.
The hosted measurement follow-up for #4451 is recorded separately in
[`../ci/VALIDATION.md`](../ci/VALIDATION.md); no coverage baseline is changed.
