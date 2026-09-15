<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# Production artifact gate (#4161)

**Run this against the Play-signed beta before promoting to production.**
The release train refuses the promotion without its build number.

## Why this exists

The artifact users install is not the artifact CI tests.

#3590: recording crashed in production and not in development, because
**Play's Automatic Integrity Protection rewrites the uploaded artifact**
and its pairip layer leaked JNI global references. No debug, profile or
sideloaded build contained the transformation that caused it, so no
amount of local testing could have reproduced it.

`fdroid_flavor_not_gms_free` is the same class of miss from the other
direction: an audit that only checked the **debug** dependency graph
passed while the release APK shipped GMS references.

So: the thing that must be driven is the thing Play serves, after Play
has rewritten it.

## Why it is a checklist and not an automation

Driving a Play-signed install needs a device or emulator **with Play
Services**, which the F-Droid flavour deliberately cannot use, and which
CI does not have. An automation that ran against a sideloaded release
would look green while testing an artifact with none of the
transformation that breaks. A checklist that is actually performed is
worth more than an automation that silently tests the wrong thing.

## The checklist

Install from the **Play Open Testing track** — not a sideload, not a
local build. Joining the track and installing through the Play Store is
what applies the signing and the Integrity rewrite.

1. **Version check.** Settings → About shows the build you intend to
   promote. (`stale_build_play_beta_lag`: "still doesn't work" is usually
   an old Open Testing build — Play propagation lags.)
2. **Cold start.** Force-stop, then launch. The map reaches usable state.
3. **A search.** Any country, any fuel. Results render with prices.
4. **▶ Start a recording** (Trips → record). This is #3590's exact path.
5. Drive or idle **at least 60 s** with the screen off — the JNI global
   reference leak needed the background path, not the foreground one.
6. **⏹ Stop the recording.** It saves, and the trip appears in the list.
7. **No crash, no ANR.** Check Settings → error log is free of new
   entries, and Play Console → Android vitals shows nothing new within
   the hour.

If OBD-II hardware is to hand, repeat 4–6 with the adapter connected —
that is the path with the most native surface.

## Recording the result

Re-dispatch the release train with:

```
channel        = production
validated_build = <the Play versionCode you just drove>
```

The `production-artifact-gate` job refuses an empty or non-numeric value
and `android-production` never runs, so a forgotten checklist **blocks
the promotion** rather than filing a note nobody reads.

## What is already automated, and stays

* **F-Droid release APK** — `scripts/audit_no_gms.sh` dex-scans the
  RELEASE artifact with strict references, wired into `fdroid.yml` and
  `fdroid-publish.yml`. That gate is not replaced by this one; it covers
  the other end of the matrix (GMS-free, different dependency graph).
* The release train already builds both stores from one commit (#3792),
  which is why there is a single place to hang this.

## Known gap

TestFlight's thinning/transform path has no equivalent gate. iOS has not
produced a #3590-class defect, so this is recorded rather than built —
if one appears, this document is where the iOS steps belong.
