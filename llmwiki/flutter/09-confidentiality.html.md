**09 · Data**

# Confidentiality & security

> Privacy claims are testable. "Your location never leaves the device" is either true — in which case you can prove it with a test and a network capture — or it is marketing. This page is about making the claims true and then keeping them true as the app grows.

**Chunk prefix** conf **Updated** 2026-08-01 **Depends on** 07 Supabase · 05 Traceability

#### On this page

1. [Start with a data inventory](#inventory)
1. [Secure storage versus plain storage](#storage)
1. [Data in transit](#transit)
1. [Secret hygiene in the repository and CI](#secrets)
1. [Permissions: ask late, explain first](#permissions)
1. [The privacy dashboard](#dashboard)
1. [Store privacy declarations](#declarations)
1. [Third-party code as a confidentiality surface](#thirdparty)
1. [Security tests that pay for themselves](#tests)

<!-- chunk: conf.inventory | tags: privacy,inventory,data-classification -->

## Start with a data inventory

Before deciding how to protect anything, write down every category of data the app touches, where it lives, and whether it ever crosses the network. Everything else follows from that table.

| Category | Stored where | Leaves the device? | Notes |
| --- | --- | --- | --- |
| Precise location | Memory only, or an encrypted box for recorded trips | **As a query parameter only**, ephemeral, never persisted server-side | The single most sensitive item in most apps |
| API keys the user entered | Platform secure store | **Never** | Also excluded from every export |
| Auth tokens | Platform secure store | To the auth backend only | Managed by the auth client; verify it uses the secure store |
| Backend URL and publishable key | Secure store or a build define | Public by design | See [the trust model](07-supabase.html#model) |
| User content (bookings, logs, entries) | Encrypted local box | Only when the user enabled sync | Sync is opt-in and reversible |
| Anonymous device identifier | Local | To the sync backend, if enabled | Not an advertising id; not shared |
| Diagnostics / trace log | Local ring buffer + file | **Only if the user explicitly shares it** | Redaction list is enforced by a test |
| Analytics | — | — | Not collected. Stating this is only credible if it is true. |

> **[RULE]**

> **The inventory is the source for three artifacts, and they must agree:** the privacy policy, the store data-safety declarations, and the app's own privacy screen. When one changes, all three change in the same pull request. A store declaration that contradicts your privacy policy is a compliance problem; one that contradicts your actual behaviour is a removal risk.

<!-- chunk: conf.storage | tags: storage,encryption,keystore -->

## Secure storage versus plain storage

Two tiers, and a clear rule for which goes where: anything that authenticates or authorises goes in the platform secure store; anything personal goes in an encrypted box whose key comes from that store.

```dart
// The encryption key for the local boxes lives in the platform secure
// store, generated once. Never a constant, never derived from something
// guessable like a device id.
Future<List<int>> _boxKey(FlutterSecureStorage secure) async {
  const k = 'hive_aes_key';
  final existing = await secure.read(key: k);
  if (existing != null) return base64Url.decode(existing);
  final fresh = Hive.generateSecureKey();
  await secure.write(key: k, value: base64UrlEncode(fresh));
  return fresh;
}
```

| Goes in the secure store | Goes in an encrypted box | May be plain |
| --- | --- | --- |
| Auth tokens | User content and history | Theme preference |
| API keys | Profiles and vehicles | Locale override |
| The box encryption key | Favourites, alerts, entries | Feature toggles |
| Backend credentials | Recorded location traces | Non-personal caches |

> **[TRAP]**

> **Symptom: a value read through the generic settings getter is always null, and the fallback looks plausible.** When a value has a dedicated accessor that reads the secure store, a generic `getSetting(key)` read of the same key compiles and returns null forever — because the value is not in that box. One project served a built-in demo dataset to every user for months because one screen bypassed the accessor. See [the one-accessor rule](01-foundations-architecture.html#storage). This is a confidentiality issue as much as a correctness one: the same mistake in reverse writes a secret to the plain box.

> **[RULE]**

> **Never log a secret, and never include one in an export.** Add both to the redaction test. The failure is usually indirect — a whole settings map dumped into a diagnostic, a request object printed on error, an exception message that embeds a URL with a token in the query string.

<!-- chunk: conf.transit | tags: network,tls,privacy -->

## Data in transit

- **HTTPS everywhere, enforced by a test.** One project has a test asserting no configured endpoint uses plain HTTP. It is ten lines and it catches the copy-pasted example URL.
- **Send the minimum.** A location-based query needs a rounded coordinate and a radius, not a full fix with altitude, speed and heading. Rounding for the [cache key](06-caching.html#keys) conveniently also reduces what you transmit.
- **Offer a coarse alternative.** If a postal-code search gives an acceptable result, offer it — then location permission becomes genuinely optional, which is both better for the user and a materially better story in the store declaration.
- **Never put a secret in a query string.** Query strings appear in server logs, proxy logs and crash reports. Headers only.
- **Consider whether a proxy leaks less than a direct call.** A tile or geocoding proxy you control means the third party sees your server rather than every user's IP — at the cost of you now holding those requests. Decide deliberately and write down which trade you took.

> **[CHECK]**

> Run the app through a capturing proxy for one full session — first launch, permission grants, a search, a sync, sign-out — and read every request. This takes half an hour and is the only way to actually know what your app sends. Do it once per release cycle; the surprises are always in a dependency, not in your code.

<!-- chunk: conf.secrets | tags: ci,secrets,supply-chain -->

## Secret hygiene in the repository and CI

Distinguish public configuration from real secrets, keep real secrets out of the tree entirely, and clean up anything CI writes to disk.

| Material | Public? | Where it lives |
| --- | --- | --- |
| Backend URL, publishable key | Yes | Committed default or build define |
| Service-role key | **No** | CI secret and the backend only. Never in the app, ever. |
| Android upload keystore + passwords | **No** | CI secret (base64) plus an off-machine backup |
| App Store Connect `.p8` key | **No** | CI secret. **Apple will not re-issue it.** |
| Certificate-repo passphrase | **No** | CI secret plus a password manager. Losing it makes the whole repo useless. |
| Play publisher service account JSON | **No** | CI secret |
| Third-party API keys | Depends | Secure store on-device if user-supplied; CI secret if build-time |

```yaml
# Restore a keystore for signing, then ALWAYS delete it — including when
# the build fails, which is when a forgotten file is most likely to be
# picked up by an artifact-upload step.
- name: Restore upload keystore
  run: |
    echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > android/app/upload.p12
    cat > android/key.properties <<EOF
    storeFile=upload.p12
    storePassword=${{ secrets.ANDROID_KEYSTORE_PASSWORD }}
    keyAlias=${{ secrets.ANDROID_KEY_ALIAS }}
    keyPassword=${{ secrets.ANDROID_KEY_PASSWORD }}
    EOF

- name: Build
  run: flutter build appbundle --release

- name: Remove signing material
  if: always()                       # ← the important part
  run: rm -f android/app/upload.p12 android/key.properties
```

> **[RULE]**

> **Maintain an "irreplaceable material" list and back it up off-machine.** Some secrets can be rotated; some cannot. An App Store Connect private key is downloadable exactly once. A certificate-repository passphrase, if lost, makes an encrypted repository permanently unreadable — one project hit precisely this and had to create a second certificate repository rather than recover the first. Write the list into the release documentation with a note on where each backup lives.

> **[RULE]**

> **Secrets are unavailable to pull requests from forks, and that is correct.** Design workflows to *degrade honestly* rather than fail confusingly: produce an unsigned artifact with a warning, skip the upload with a loud message. A dependency-update bot's pull request must still be able to build and test. See [honest degradation](04-robustness.html#honest).

> **[CHECK]**

> Run a secret scanner over the full history, not just the working tree — `gitleaks detect --no-git=false` or equivalent. A key committed and then removed is still in the history and still compromised. If you find one, rotate it; deleting the commit is not sufficient because clones and forks exist.

<!-- chunk: conf.permissions | tags: permissions,ux,app-store -->

## Permissions: ask late, explain first

Request a permission at the moment the user asks for the feature that needs it, after a screen explaining why — and that explanation screen must never block the app.

> **[RULE]**

> **A pre-permission explainer is Continue-only, and always proceeds.** This is an App Store review requirement and it was the basis of a real 5.1.1 rejection. The screen may explain and it may offer Continue; it may not gate the app behind granting. The user must be able to reach the app's functionality — degraded, but reachable — without granting anything.

| Permission | Ask when | Degrade to |
| --- | --- | --- |
| Location (while in use) | The user taps "search near me" | Manual location entry / postal code |
| Location (background) | Only when a background feature is enabled, and never at first launch | Foreground-only operation, clearly labelled |
| Bluetooth | The user opens the device-pairing screen | Everything that does not need a device |
| Camera | The user taps scan or capture | Manual entry, file picker |
| NFC | The user opens the tap surface | Manual identifier entry — see [page 12](12-nfc-rfid.html) |
| Notifications | The user enables a feature that notifies | In-app indicators |
| Storage | Never, if you can avoid it | A document picker needs no permission on modern Android |

> **[TRAP]**

> **Symptom: your manifest declares permissions you have never used.** Dependencies merge their manifests into yours. One project shipped microphone, phone-state and legacy-storage permissions purely from libraries — nothing in the app ever used them. Users read the permission list, and reviewers do too. Audit the *merged* manifest, not your source manifest, and remove unwanted entries with a manifest-merger removal directive.

> ```xml
> <uses-permission android:name="android.permission.RECORD_AUDIO"
>                  tools:node="remove" />
> ```

> **[CHECK]**

> Inspect the merged manifest after every dependency change: `./gradlew :app:processPlayReleaseManifest` then read `app/build/intermediates/merged_manifests/…/AndroidManifest.xml`. Add a test asserting the permission set matches an expected list, so a new dependency's additions are a build failure rather than a store surprise.

<!-- chunk: conf.dashboard | tags: privacy,ux,gdpr,export -->

## The privacy dashboard

One screen where the user can see every category of stored data, export all of it, and delete all of it. This is both a legal requirement in several jurisdictions and the most credible possible statement of your privacy claims.

| Element | Behaviour |
| --- | --- |
| **Per-category row counts** | What is stored, how much of it, in the user's own terms |
| **Export** | One tap to JSON and CSV. Everything the user created, nothing secret. |
| **Diagnostics export** | The trace log as a separate, clearly-labelled action |
| **Delete everything (local)** | One tap, confirmed once, actually deletes — including caches |
| **Delete everything (server)** | If sync is enabled, a distinct action that removes server rows too |
| **Plain-language summary** | What never leaves the device, what does, and under what condition |
| **Sync status** | Whether it is on, where it points, when it last ran |

> **[RULE]**

> **Export must exclude every secret, and a test must prove it.** Generate an export in a test with secrets populated and assert that no known secret key name or value appears in the output. Users share exports with support, in bug reports, and in public forums.

> **[RULE]**

> **"Delete everything" must include caches and derived data.** A delete that clears the user's entries but leaves a cached response containing the same rows has not deleted anything. Enumerate the stores in the delete path the same way you enumerate them for [cache invalidation](06-caching.html#invalidation), and test it by asserting the store is empty afterwards.

A useful addition observed in one project: a **test button for a hard-to-reproduce surface** — a control that pushes a synthetic signal so a driving-mode overlay can be verified from a desk rather than a moving car. It costs little and turns an untestable feature into a testable one.

<!-- chunk: conf.declarations | tags: app-store,play,compliance -->

## Store privacy declarations

Both stores require a structured declaration of what you collect. Derive it from the inventory, keep it in the repository, and treat a change to it as a change requiring review.

```markdown
# docs/play-store/DATA_SAFETY.md — the answer sheet, version-controlled

- Collects or shares user data?      Yes
- All data encrypted in transit?     Yes (HTTPS/TLS everywhere)
- Users can request deletion?        Yes — in-app: Settings → Delete all data;
                                     server: Sync → Data transparency → Delete
- Privacy policy URL:                https://…/privacy-policy/

## Location
Collected? Yes · Approximate · Shared with third parties? Yes — sent to the
price API as a search parameter · Processed ephemerally? Yes, never stored
server-side · Required or optional? Optional (postal-code search available)
· Purpose: app functionality

## Device or other IDs
Device IDs? No · Other identifiers? Yes — an anonymous UUID if sync is enabled
· Shared? No · Optional? Yes · Purpose: app functionality

## NOT collected
Name, email (unless the user creates an account), phone, contacts, photos,
messages, files, calendar, health, financial info, browsing history,
installed apps, advertising ID, crash-free analytics.
```

> **[RULE]**

> **Keep the answer sheet in the repository, next to the privacy policy, and diff them against each other.** The store console is a form you fill in once and forget; the repository copy is reviewable in a pull request. When a feature adds a data category, the reviewer sees the declaration change alongside the code.

Apple's equivalent is the privacy nutrition label plus, since recent SDK requirements, a **privacy manifest** for your app and for each third-party SDK that requires one. Audit your dependency list against Apple's required-reason API list before a submission; a missing manifest is an automated rejection at upload, not a review finding — so it fails fast, which is at least merciful.

> **[TRAP]**

> **Symptom: the store's privacy-policy URL points somewhere that no longer exists.** Store consoles hold their own copy of the URL, and a documentation-site restructure does not update it. One project moved its policy to a new path and had to update the console field by hand. Add "verify the privacy-policy URL resolves" to the go-live checklist in [page 19](19-go-live.html).

<!-- chunk: conf.thirdparty | tags: dependencies,supply-chain,licensing -->

## Third-party code as a confidentiality surface

Every dependency can make network calls you did not write. Treat the dependency list as part of the privacy inventory.

- **Audit what a new dependency pulls in transitively**, not just what it declares. An innocuous-looking plugin can drag in an entire proprietary services stack.
- **Run a licence audit in CI.** Both projects forbid GPL dependencies; the check is a script over the resolved dependency set. Catching it at add-time is cheap, catching it at release-time is not.
- **Prefer packages that need no runtime permission.** A document-picker package that routes through the OS picker needs no storage permission; a file-browser package does.
- **For a build channel that forbids proprietary code, prove the absence at the bytecode level**, not the declaration level. Reference-level proof is a stricter bar than "no declared dependency" and it is the bar F-Droid actually applies — see [page 17](17-fdroid.html#audit).
- **Compile out anything that phones home, per channel.** One project ships a crash reporter on the store builds and removes it entirely from the libre build, because a reporting SDK is classified as tracking there.

> **[WHY]**

> A dependency graph tells you what was *declared*. It does not tell you what survived into the shipped artifact, and it does not catch a dangling type reference that a scanner will flag. One project's catalog submission was rejected on references that a dependency-graph audit — and even a debug-build bytecode audit — could not see, because only the release-mode shrinker removes the dead code that carries them. If a channel's scanner reads the artifact, your audit must read the artifact too.

<!-- chunk: conf.tests | tags: testing,security,ci -->

## Security tests that pay for themselves

Six tests, each a few dozen lines, that between them cover the failure modes that actually occur.

| Test | Asserts |
| --- | --- |
| **No hard-coded secrets** | No source file contains a string matching known key shapes (JWT prefix, private-key header, long base64 assigned to a suggestive name) |
| **No plaintext endpoints** | Every configured URL is `https://` |
| **Manifest security** | No `allowBackup` where it would leak data, no cleartext traffic, no exported component that should not be, and the permission set matches the expected list |
| **Export redaction** | A generated export with secrets populated contains none of them |
| **Authorisation matrix** | For each role, an operation that should be denied *is* denied — run against the real backend policies, not a fake |
| **Privacy-doc parity** | The privacy policy, the data-safety sheet and the in-app summary list the same categories |

```dart
test('exports contain no secret material', () async {
  await apiKeys.write('tankerkoenig', 'SECRET-KEY-VALUE');
  await secure.write(key: 'auth_token', value: 'SECRET-TOKEN-VALUE');

  final export = await PrivacyExporter(storage, apiKeys).toJson();

  expect(export, isNot(contains('SECRET-KEY-VALUE')));
  expect(export, isNot(contains('SECRET-TOKEN-VALUE')));
  for (final k in const ['auth_token', 'api_key', 'service_role', 'password']) {
    expect(export.toLowerCase(), isNot(contains(k)));
  }
});
```

> **[CHECK]**

> Once per release, do the three manual checks no test replaces: read the merged manifest, run one full session through a capturing proxy, and open an export in a text editor and read it. Each takes minutes and each has caught something that automation did not.

#### Sources for this page

- One project's privacy dashboard, its committed data-safety answer sheet, its security test suite (hard-coded secrets, plaintext endpoints, manifest security, RLS), and its decision to compile the crash reporter out of the libre channel.
- Both projects' CI signing steps with their `if: always()` cleanup, and one project's irreplaceable-material list.
- Post-mortems supplying the traps: the unused permissions merged in from dependencies, the moved privacy-policy URL, the accessor bypass, the lost certificate-repository passphrase, and the catalog rejection on bytecode references invisible to a dependency-graph audit.
- The App Store 5.1.1 rejection that produced the Continue-only pre-permission rule.

The data inventory table is a composite of both projects; your categories will differ. The test snippets are illustrative reconstructions.
