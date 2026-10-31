<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

Implementation-Session: <!-- unique session/thread ID; reviewer must differ -->

<!-- A different session reviews this exact head and records the required
independent-session-review status. See docs/ci/independent-review.md.
Never record your own approval, bypass the gate, or reuse a prior SHA's review. -->

## What
<!-- One sentence describing the change -->

## Why
<!-- Link the issue: Refs #N for partial delivery; Closes #N only for whole
acceptance including required external evidence. Follow
[Ready/Done/STOP contract](../docs/guides/issue-exit-contract.md). -->

## Checkpoint and exit
<!-- Outcome/current-vs-expected, real producer+consumer, non-goals, necessary
producer checkpoint vs release/device/operator gate. Acceptance satisfied and
remaining evidence; stop after the agreed checkpoint. -->

## Type of Change
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Enhancement (improvement to existing feature)
- [ ] Refactor (no functional changes)
- [ ] Documentation
- [ ] CI/CD or tooling
- [ ] Breaking change (fix or feature that would cause existing functionality to change)

## How
<!-- Keep/adapt/replace/already implemented: proposed -> chosen, rationale,
trade-offs, preserved behavior, compatibility/rollback and named proof. -->

## Testing
- [ ] `flutter analyze` passes (zero warnings)
<!-- Base/final SHA; acceptance -> actual entry/fixture -> test path/name ->
command/original exit/artifact. Reuse existing evidence; no extra suite run just
for reporting. Label PASS/FAIL/NOT RUN/BLOCKED/DEFERRED; explain inapplicable
layers. Code verified, physical evidence and released/installed are distinct. -->
- [ ] Applicable tests pass on the current candidate
- [ ] Required device/provider/operator evidence recorded, or explicitly pending
- [ ] Direct regressions covered; existing adequate tests reused

## Checklist
- [ ] Code follows existing patterns and conventions
- [ ] User-facing strings are in ARB files (not hardcoded)
- [ ] No API keys, secrets, or credentials in the diff
- [ ] No unnecessary files committed (build artifacts, IDE configs)
- [ ] PR is under 400 lines changed (excluding generated files)

## Screenshots
<!-- Before/after if UI change, otherwise delete this section -->

## Breaking Changes
<!-- Describe any breaking changes and migration steps, or delete this section -->
