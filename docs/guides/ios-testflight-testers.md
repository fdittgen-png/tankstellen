<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# Add an external TestFlight tester

Enroll an external iOS tester into the app's TestFlight beta group(s) so they
receive **all current and future** builds for that group — without logging
into App Store Connect by hand.

## How to run

GitHub → **Actions** → **iOS TestFlight Testers** → **Run workflow**
(`workflow_dispatch`). Or from the CLI:

```bash
# Add the default tester (florian.dittgen@trelleborg.com) to ALL external groups
gh workflow run ios-testers.yml

# Add a specific tester, optionally to specific group(s)
gh workflow run ios-testers.yml \
  -f email="someone@example.com" \
  -f groups="External Testers" \
  -f first_name="Some" \
  -f last_name="One"
```

### Inputs

| Input        | Required | Default                          | Meaning                                                                 |
| ------------ | -------- | -------------------------------- | ----------------------------------------------------------------------- |
| `email`      | yes      | `florian.dittgen@trelleborg.com` | Tester email. An invite email is sent to this address.                  |
| `groups`     | no       | _(empty)_                        | Comma-separated group names. **Empty → add to every external group.**   |
| `first_name` | no       | _(empty)_                        | Tester first name.                                                      |
| `last_name`  | no       | _(empty)_                        | Tester last name.                                                       |

When `groups` is omitted the workflow enumerates the app's external beta
groups and adds the tester to **each** of them, so "all current and future
tests" is covered regardless of how the group is named. The run log prints the
discovered group names (internal and external) so you can see exactly which
group the tester landed in.

## Prerequisites

- The app (`de.tankstellen.tankstellen`) must already have a **TestFlight
  build** and **at least one external beta group** in App Store Connect.
  Create the group under App Store Connect → TestFlight first; the workflow
  adds testers to existing groups, it does not create them. If no external
  group exists (and no matching `groups` name is passed) the lane fails with a
  clear message.
- The App Store Connect API key secrets must be configured (they already are
  for the TestFlight build workflow): `APP_STORE_CONNECT_API_KEY_BASE64`,
  `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_API_ISSUER_ID`.

## What happens

- The tester receives a TestFlight **invite email**. They accept it, install
  TestFlight, and from then on get every build distributed to that group.
- The operation is **idempotent**: re-running it for an already-enrolled
  tester is a no-op, not an error.

## Why `workflow_dispatch` only

This is an outward-facing, live App Store Connect mutation that emails a real
person. It must never run automatically, so the workflow has no `push` /
`schedule` triggers — the maintainer (or the orchestrator) dispatches it by
hand. Under the hood it reuses the same App Store Connect API key and decode
step as `ios-testflight.yml`, and the `manage_testers` lane in
`ios/fastlane/Fastfile`.
