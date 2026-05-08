# iOS code signing — fastlane match

iOS signing identities (development cert + appstore distribution cert) and the
matching provisioning profiles live in a separate, encrypted private repo:
**`fdittgen-png/tankstellen-ios-certs`**. The contents are AES-encrypted with
`MATCH_PASSWORD` and managed by [fastlane match](https://docs.fastlane.tools/actions/match/).

This setup is **already bootstrapped** — there are working certs in the match
repo, GitHub Actions is wired up to fetch them via App Store Connect API key
auth, and the Apple Developer Portal already shows the corresponding profiles.
You only revisit this doc when (a) onboarding a new dev workstation,
(b) renewing an expired cert, or (c) something has gone visibly wrong.

## Prerequisites for any local work

- macOS workstation. Linux can't sign for iOS.
- Xcode and command-line tools installed.
- `bundle install` from the repo root, which reads `Gemfile` and installs
  fastlane into `vendor/bundle/`.
- Two pieces of secret material:
  - **`MATCH_PASSWORD`** — decrypts the match repo. Stored in 1Password under
    "tankstellen — fastlane match". Without it, the certs in the match repo
    are useless.
  - The **App Store Connect API key** (`AuthKey_<KeyID>.p8`). Only needed for
    operations that touch the Apple Developer Portal (creating/renewing
    certs, registering devices). Day-to-day cert *fetching* doesn't need it.

The corresponding GitHub repository secrets are:

| Secret | Used by |
| --- | --- |
| `MATCH_PASSWORD` | every match invocation, local or CI |
| `APP_STORE_CONNECT_API_KEY_ID` | mint/renew certs, upload to TestFlight |
| `APP_STORE_CONNECT_API_ISSUER_ID` | same |
| `APP_STORE_CONNECT_API_KEY_BASE64` | CI only — the `.p8` content, base64-encoded |

## Onboarding a new developer workstation

You need a **read-only** clone of the match repo's certs into your local
keychain. You do **not** need the App Store Connect API key for this.

```bash
cd ios
export MATCH_PASSWORD='<value from 1Password>'
bundle exec fastlane match_dev      # development cert + profile, debug builds
bundle exec fastlane match_appstore # appstore cert + profile, release builds
```

Both lanes run in **readonly mode** locally (the Matchfile defaults `readonly`
to `ENV["CI"] == "true"`, and our lanes don't override it for normal flows).
That guarantees you cannot accidentally regenerate certs and invalidate
everyone else's keychain.

After running, Xcode picks up the imported profiles automatically the next
time you open `ios/Runner.xcworkspace`.

## Renewing an expired or revoked cert

Apple distribution certs expire every 12 months. Apple development certs
expire every 12 months as well. Fastlane will tell you when one is close to
expiry by failing a `match` run with a clear "this cert is no longer valid"
message.

Renewal must run from a developer workstation, **never** from CI. CI is
hard-pinned to readonly mode in the Matchfile.

```bash
cd ios
export MATCH_PASSWORD='<value from 1Password>'
export APP_STORE_CONNECT_API_KEY_ID='CG5N5AKMH9'
export APP_STORE_CONNECT_API_ISSUER_ID='ae6fe867-5d68-454a-a38b-5f9a98a5be24'
export ASC_API_KEY_FILEPATH="$HOME/Downloads/AuthKey_CG5N5AKMH9.p8"

# Force regeneration of the relevant cert + profile + push to match repo
bundle exec fastlane match appstore --force
# Or for dev:
bundle exec fastlane match development --force
```

After the run, **delete the local `.p8`** (`rm $ASC_API_KEY_FILEPATH`).
The base64 of the same `.p8` lives in GitHub Actions as
`APP_STORE_CONNECT_API_KEY_BASE64` and that is the canonical copy.

## Adding a new physical device

Required if you want to install a debug build via Xcode → device for hands-on
debugging. (TestFlight installs do **not** need this — TestFlight uses the
appstore profile, which doesn't enumerate device UDIDs.)

```bash
cd ios
export APP_STORE_CONNECT_API_KEY_ID='CG5N5AKMH9'
export APP_STORE_CONNECT_API_ISSUER_ID='ae6fe867-5d68-454a-a38b-5f9a98a5be24'
export ASC_API_KEY_FILEPATH="$HOME/Downloads/AuthKey_CG5N5AKMH9.p8"

# Replace the udid + name with the values from Xcode → Window → Devices
bundle exec fastlane run register_device udid:<UDID> name:"Florian iPhone"
bundle exec fastlane match development --force
```

The first command registers the device with Apple; the second regenerates
the development profile to include it.

## If something is wrong

- **Match repo cannot be cloned**: verify your local git auth has read access
  to `fdittgen-png/tankstellen-ios-certs`. CI uses
  `MATCH_GIT_BASIC_AUTHORIZATION` (a base64 of `username:PAT`); locally you
  use whatever git credential helper your workstation has.
- **`MATCH_PASSWORD` rejected**: Match's encryption is case-sensitive. Triple-
  check the value, including punctuation. If the password is genuinely lost,
  the only path forward is `fastlane match nuke`, which revokes every cert
  and profile in the match repo, plus rerunning bootstrap. **This invalidates
  every TestFlight build that's already uploaded** — coordinate before doing
  it.
- **Cert appears expired but the calendar says it isn't**: Apple sometimes
  revokes a cert server-side without expiring it (e.g., after a security
  incident on the developer account). Run `fastlane match` with `--force`
  for the affected type to regenerate.

## Why this layout

- The match repo is **separate** so a write breach of the main repo doesn't
  leak signing material.
- The repo is **encrypted** so a write breach of the match repo still doesn't
  expose private keys without `MATCH_PASSWORD`.
- CI auth uses the **App Store Connect API key**, not Apple ID + 2FA, so
  releases never block on a TOTP prompt.
- Fastlane is pinned to **`~> 2.227`** in the Gemfile, narrow enough to keep
  CI reproducible but wide enough to absorb patch-level fixes.
