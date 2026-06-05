# Go-Live Runbook — Sparkilo (Google Play + F-Droid)

Single source of truth for shipping Sparkilo. Last verified **2026-06-05** against
master. App id `de.tankstellen.fuelprices`, current version **`5.0.0+5132`**.

## Where things stand (nothing is live yet)

| Surface | State | What's left |
|---|---|---|
| **Google Play** | App exists ("Sparkilo: Cheap Fuel & EV"); **Production is empty** — a *draft* with **42 test installs** (1 country). Listing text + 6-locale changelogs + screenshots ready. | Create the production release (promote the existing AAB) + finish the required Console declarations. |
| **F-Droid — official catalog** | **Not submitted** (`f-droid.org/packages/de.tankstellen.fuelprices` → 404). Recipe prepped, **`fdroid lint` clean**, `AuthorEmail` bound. | Fork fdroiddata as your GitLab account → MR. F-Droid signs it; **no keystore needed**. |
| **F-Droid — self-hosted repo** | Pipeline built (Pages `/fdroid`), **never bootstrapped** (repo empty, fingerprint is a placeholder). | App release keystore + repo key, then `scripts/fdroid_publish.sh`. |
| **iOS App Store** | Metadata complete (5 locales). | Out of scope here — needs Apple provisioning/TestFlight. |

## The one cross-cutting item — the app release keystore

`key.properties` / a release `.jks` does **not** exist in the repo. It's needed to
self-sign the F-Droid self-hosted APK, and it's your Play **upload key**.
**But Google Play already has 42 signed installs**, so Play App Signing is enrolled
and you can **promote the existing AAB** to production without minting anything new.
So the keystore is only a hard blocker for the **self-hosted F-Droid** path.

One-time ceremony (permanent, secret — back it up):
```bash
keytool -genkeypair -v -keystore ~/keystores/sparkilo-release.jks \
  -alias sparkilo -keyalg RSA -keysize 2048 -validity 10000
```

---

## 1. Google Play — create the production release

The empty Production dashboard is normal; you just haven't cut a production release.

1. **Finish required declarations** (Console → *Vue d'ensemble de la publication* /
   Publishing overview — clear every red item): **Data safety** (content ready in
   `docs/play-store/DATA_SAFETY.md`), **Content rating** (IARC questionnaire),
   **Target audience**, **Ads** (none), **App access**, **Privacy policy**
   (https://fdittgen-png.github.io/tankstellen/ — live), pricing (free) + countries.
2. **Production → Créer une version.** Under *App bundles*, **Ajouter depuis la
   bibliothèque** to reuse the already-signed AAB behind the 42 installs (or upload
   a fresh one — `flutter build appbundle --release --flavor play`, or let `deploy.yml`
   build it on a `v*` tag).
3. **Release notes**: the 6-locale `changelogs/5132.txt` are ready.
4. **Roll out** at **10–20 %** staged; watch crash/ANR 3–7 days; then 100 %.
   (CI alternative: push a `v*` tag → `deploy.yml` uploads to the *internal* track;
   `scripts/promote_play_store.sh` promotes with a rollout %.)

## 2. F-Droid — official catalog (fdroiddata MR) — recipe is ready

`fdroid lint` passes; categories (`Navigation`, `Internet`) valid; `AuthorName:
Florian DITTGEN` + `AuthorEmail: fdittgen@gmail.com` set. F-Droid's buildserver
compiles + signs — **you do not need your keystore**. Submitter identity = the GitLab
account that opens the MR (you, id `38723484`). See `docs/guides/fdroid-submission.md`.

```bash
# signed in to GitLab as your account:
#  1. Fork gitlab.com/fdroid/fdroiddata → gitlab.com/<your-username>/fdroiddata
cp metadata/de.tankstellen.fuelprices.yml  <fork>/metadata/
cd <fork> && git config user.email fdittgen@gmail.com
fdroid lint de.tankstellen.fuelprices
fdroid build -v -l de.tankstellen.fuelprices    # then pin the NDK it reports in the recipe
git checkout -b de.tankstellen.fuelprices
git commit -am 'New App: de.tankstellen.fuelprices' && git push
#  open the MR with the "New App" label → review takes days–weeks
```
**Needed from you:** your GitLab **@username** for the fork URL.

## 3. F-Droid — self-hosted repo (instant, fully yours)

Needs the keystore above. Then:
```bash
export ANDROID_KEYSTORE_PATH=~/keystores/sparkilo-release.jks
export ANDROID_KEYSTORE_PASSWORD=…   ANDROID_KEY_ALIAS=sparkilo
export FDROID_REPO_KEYSTORE_PASSWORD=…   FDROID_REPO_KEY_PASSWORD=…   # you choose
bash scripts/fdroid_publish.sh        # builds+signs, fdroid init (first run), fdroid update
# paste the printed SHA-256 fingerprint into docs/index.html, commit + push
```
→ live at `https://fdittgen-png.github.io/tankstellen/fdroid`. `fdroidserver` is
installed locally.

---

## Done in-repo (verified)

- Version `5.0.0+5132` consistent across pubspec + both F-Droid recipes.
- Play listing: title / short / full (6 locales) + `changelogs/5132.txt` + 8
  screenshots/locale + feature graphic + icon (all git-tracked).
- iOS App Store: name / subtitle / description / keywords / promo (5 locales).
- F-Droid: GMS-free flavor + dual-layer audit; both recipes carry `Summary` /
  `Description` (GMS-free-accurate: OCR/barcode unavailable) + author identity;
  `fdroid lint` clean.
- `DATA_SAFETY.md` written; privacy policy live; pipelines (`deploy.yml`,
  `fdroid-publish.yml`, `play-store-listing.yml`) wired.

## Open decision

**Version label.** `5.0.0+5132` has been in pubspec since ~2026-04-28 with ~30+
commits since. Either ship as-is (nothing was ever published, so the label is free)
or bump to `5.1.0+5133` (`scripts/release.sh` + regenerate 6-locale changelogs +
re-pin both F-Droid recipes). I can do the bump prep on request.

## Needs you (credentials / console / ceremony — not automatable)

1. **Play**: complete the required declarations + create/roll out the production
   release (Console).
2. **F-Droid official**: your GitLab @username → fork + MR (your GitLab login).
3. **F-Droid self-hosted**: create the keystore + choose repo-key passwords → I run
   `fdroid_publish.sh`.
4. **(Optional)** decide the version label.

---

## Play production pre-submission gap check (verified 2026-06-05)

### 🚩 The one thing that gates everything — verify FIRST
**Closed-testing access requirement.** Personal Play accounts created after
**2023-11-13** must run a **closed test with ≥12 testers opted in for 14 continuous
days**, then file **"Apply for production access"** (Google reviews ~7 days). The
threshold dropped 20→**12** on 2024-12-11. **Open-testing and internal installs do
NOT count** — only opted-in *closed-track* testers held 14 days. The "42 installs"
does **not** satisfy it.
- **Check:** Production → can you actually click *Send for review*, or is there an
  "Apply for production access" banner? If blocked, production today is impossible
  (14-day gate); start the closed test now. If the account predates 2023-11-13 or is
  an org account, the gate doesn't apply.

### Already done — no action
- **AAB**: `2026061061` (5.0.0) is uploaded & Active in Play → **promote it** (no
  rebuild). Open testing live in 39 countries.
- Privacy policy (live), data-safety content, account-deletion (in-app + TankSync),
  listing text + 8 screenshots/locale (6 langs), **feature graphic + icon now present
  for all 6 locales**, release notes (5132 content), target API 36, clean permissions
  (no Ad ID / background-location / SMS → no extra permission forms).

### Console-only, do this afternoon (every input is prepped)
- **Developer identity verification + $25 fee** — must be complete first.
- **App content declarations** — Content rating (IARC: Utility/Reference, No to
  violence/sexual/gambling/UGC, declare location); Target audience (18+, not for
  children); Ads = **No**; App access = **All functionality available without special
  access**; Government / Financial / Health / News / COVID / Advertising-ID = **None /
  No** (submit each).
- **Data safety** (fill from `DATA_SAFETY.md`): collects + shares = Yes; encrypted in
  transit = Yes; deletion = Yes; URL = the privacy policy. Only two data types —
  **Approximate location** (Collected Yes, **Shared Yes** → fuel APIs, ephemeral,
  optional) and **Other IDs** anonymous UUID (Collected Yes iff TankSync, Shared No).
  **Device IDs / Advertising ID = NOT collected.** Everything else = Not collected.
  No account-deletion URL (anonymous model).
- **Release flow**: select **countries** (currently 0) → confirm AAB `2026061061` →
  paste the `changelogs/5132.txt` content as release notes → *Review* (clear all
  Errors) → *Start rollout to production* → check **Managed Publishing** isn't holding
  it.

### Not required (skip)
Pre-registration, app indexing (deep links), and the pre-launch report are all
**optional** — none block a production submission.

---

## F-Droid & Apple production readiness (verified 2026-06-05)

### F-Droid — **needs-user-action** (recipe is submission-ready)
Both recipes are complete and `fdroid lint`-clean (Summary/Description/AuthorName/
AuthorEmail/Categories/Builds/AutoUpdate). The NDK comment now records the real
value: `android/app/build.gradle.kts` uses `flutter.ndkVersion` → Flutter 3.41.9 =
**28.2.13676358 (r28b)**; uncomment + confirm against F-Droid's buildserver on the
first MR `fdroid build`. Remaining is user-owned:
- **Official MR:** your GitLab @username → fork fdroiddata → lint/build → pin NDK
  from the build log → MR. (F-Droid signs it — no keystore needed.)
- **Self-hosted:** app release keystore + repo key → `scripts/fdroid_publish.sh`.

### Apple — **metadata-ready, not submittable today** (no in-repo blocker left)
Provisioning is **resolved** (fastlane match + `fdittgen-png/tankstellen-ios-certs`
+ active enrollment; nightly `ios-testflight.yml` produces signed builds).
`ITSAppUsesNonExemptEncryption=false` set; bundle `de.tankstellen.tankstellen`;
all 5 locales' metadata within Apple limits. **Now added:** the required
`privacy_url` (live policy) + `support_url` (repo issues) + `marketing_url` for all
5 locales. What still gates an App Store submission (all off-repo, your action):
- **iOS App Store screenshots** — none exist in Apple sizes; need ≥1 iPhone
  **6.9″** set (1290×2796) + ≥1 iPad **13″** set (2064×2752, app is universal),
  captured from a build/simulator. The Android shots don't qualify.
- **App Store Connect (console-only):** App Privacy nutrition labels, Age Rating,
  Primary Category, Pricing & Availability, Content Rights, **EU DSA trader status**.
- **A build attached + submitted:** promote a TestFlight build (signed IPA) to the
  App Store version, then submit for review.
- **iOS Share Extension (#2736) — Xcode + Apple signing, optional pre-launch:**
  the cross-platform Dart receiver + the iOS extension source ship in-repo
  (`ios/ShareExtension/`, inline `ShareIntentBridge` in `AppDelegate.swift`), but
  the extension is **not yet wired into `Runner.xcodeproj`** (kept out so the
  host build stays green). To enable "share a receipt into Sparkilo" on iOS,
  follow `docs/guides/ios-share-extension.md`: register the extension App ID
  (`de.tankstellen.tankstellen.ShareExtension`) + App Group under the Apple
  Developer account, add the target in Xcode, re-provision (fastlane match
  `--force`). The host app ships fine without it; this is an additive feature,
  not a launch gate.
