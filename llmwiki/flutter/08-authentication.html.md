**08 · Data**

# Authentication & Google sign-in

> You can offer Google sign-in without shipping a single line of Google's code. Browser-delegated OAuth is fewer dependencies, works on every platform including a libre build with no Play Services, and — the part that actually matters — keeps the credential handling in a component the user already trusts.

**Chunk prefix** auth **Updated** 2026-08-01 **Depends on** 07 Supabase · 09 Confidentiality

#### On this page

1. [SDK versus browser OAuth](#choice)
1. [Modelling providers as data](#provider)
1. [Redirect URLs per platform](#redirect)
1. [Configuring Google as a provider](#config)
1. [Anonymous accounts and the upgrade path](#anon)
1. [Linked identities](#linking)
1. [Sessions, refresh and sign-out](#session)
1. [Device pairing without an account](#pairing)
1. [Testing an auth layer](#testing)

<!-- chunk: auth.choice | tags: oauth,architecture,decision -->

## SDK versus browser OAuth

The native Google sign-in SDK gives you a one-tap account picker. Browser OAuth gives you everything else. For most apps, everything else wins.

|   | Native SDK (`google_sign_in`) | Browser OAuth |
| --- | --- | --- |
| Account picker UX | Native sheet, one tap, no browser | Custom Tab / `ASWebAuthenticationSession`; still one tap if already signed in |
| Dependency weight | Pulls Play Services on Android | None beyond the auth client you already have |
| Works in a GMS-free build | **No** | Yes |
| Works on desktop / web | Partially, with separate plugins | Yes, same code path |
| Adding a second provider | A second SDK, second config, second code path | One enum value |
| Credential handling | In your process | In the system browser — outside your process entirely |
| Setup burden | SHA-1 fingerprints per signing key, per store | One redirect URL per platform |

> **[WHY]**

> The native SDK ties an OAuth client to your app's signing certificate. Play App Signing means the certificate that signs the shipped artifact is *not* the one you uploaded, so you need both fingerprints registered. Add a debug key, an F-Droid build signed by a third party, and a CI key, and you have four fingerprints to keep in sync across two consoles — with the failure mode being a sign-in button that works in debug and fails silently in production. Browser OAuth has no fingerprint concept at all.

> **[RULE]**

> **If any distribution channel forbids proprietary dependencies, browser OAuth is not a preference — it is the only option.** A libre build cannot link Play Services. Choosing the SDK means either dropping social sign-in from that channel or maintaining two auth implementations.

<!-- chunk: auth.provider | tags: oauth,modelling,dart -->

## Modelling providers as data

An enum with a display label and a wire name, plus a resolver that still recognises retired providers so existing linked accounts keep rendering.

```dart
/// Social sign-in providers offered next to e-mail + password.
/// Browser-based OAuth, no vendor SDK — so the libre build stays free of
/// proprietary services.
///
/// Google alone: Microsoft, Apple and Facebook were once offered but never
/// configured server-side, so every tap on them ended in a provider error.
/// A button that cannot work is worse than no button. [fromWire] still
/// resolves the retired ids so an account that linked one keeps rendering.
enum SocialProvider {
  google('Google', 'google');

  const SocialProvider(this.label, this.wireName);

  /// Brand name — deliberately NOT translated.
  final String label;

  /// The backend's provider id.
  final String wireName;

  /// The catalog entry for a stored identity's provider id, or null for
  /// non-social identities ('email', 'phone', …).
  static SocialProvider? fromWire(String provider) =>
      values.where((p) => p.wireName == provider).firstOrNull;
}

/// One identity attached to the signed-in account.
typedef LinkedIdentity = ({String id, String provider});
```

> **[RULE]**

> **Never render a provider button that is not configured server-side.** An unconfigured provider produces an opaque error after the user has already left your app for a browser — the worst possible place to fail. Ship the enum with only what is actually wired up, and keep `fromWire` tolerant so historical identities still display.

> **[RULE]**

> **Provider names are brand names: never localise them.** "Google" is "Google" in every locale. Mark the field with whatever exemption comment your no-hard-coded-strings lint uses, so the exemption is visible and justified rather than looking like an oversight.

<!-- chunk: auth.redirect | tags: oauth,deep-links,platform -->

## Redirect URLs per platform

The OAuth callback needs somewhere to land, and that somewhere differs between web and native — one branch, resolved once.

```dart
static String get _redirect => kIsWeb
    // Web: back to the page that started the flow. Must be listed in the
    // backend's allowed redirect URLs, or the provider refuses.
    ? Uri.base.origin + Uri.base.path
    // Native: a custom scheme registered on each platform.
    : 'de.example.app://login-callback';

Future<void> signInWithSocial(SocialProvider provider) async {
  await _client.auth.signInWithOAuth(
    _oauth(provider),
    redirectTo: _redirect,
  );
}
```

Register the scheme on every native platform:

| Platform | Where | What |
| --- | --- | --- |
| Android | `AndroidManifest.xml` | An `intent-filter` with `VIEW` + `BROWSABLE` + `DEFAULT` and `<data android:scheme="de.example.app"/>` |
| iOS / macOS | `Info.plist` | `CFBundleURLTypes` with the same scheme |
| Windows | Installer | An `HKLM` protocol-handler registration — see [page 16](16-windows.html) |
| Web | Backend config | Every origin you deploy to, listed as an allowed redirect URL |

> **[TRAP]**

> **Symptom: sign-in works locally and fails on the deployed web build with a redirect error.** Each origin — `localhost` with its port, the preview URL, the production URL, and a project-pages URL with a path prefix — is a separate entry in the backend's allowed-redirect list. Add them all when you add the first, or you will rediscover this on every new deployment target.

> **[TRAP]**

> **Symptom: the browser opens, the user authenticates, and the app never comes back to the foreground.** The scheme is not registered, or it is registered with the wrong case, or on Android the intent filter is missing `BROWSABLE`. Test the scheme independently of OAuth before debugging the OAuth flow:

> ```bash
> adb shell am start -a android.intent.action.VIEW -d "de.example.app://login-callback"
> xcrun simctl openurl booted "de.example.app://login-callback"
> ```

> If that does not foreground your app, the problem is the scheme registration and nothing to do with authentication.

<!-- chunk: auth.config | tags: google,oauth,configuration -->

## Configuring Google as a provider

With browser OAuth, Google configuration happens entirely in two consoles and never in your app.

1. **Google Cloud Console → APIs & Services → Credentials.** Create an OAuth 2.0 *Web application* client. Web, not Android or iOS — the browser flow is a web flow regardless of which device it runs on. This is the point most first-time setups get wrong.
1. **Authorised redirect URI:** your auth backend's callback endpoint (for Supabase, `https://<project>.supabase.co/auth/v1/callback`). Not your app's custom scheme — the provider redirects to your backend, and your backend redirects to your app.
1. **OAuth consent screen:** app name, support email, logo, and the scopes. Keep the scopes minimal — `email` and `profile` are enough for identity. Anything more triggers a verification review and a warning banner for users.
1. **Copy the client id and secret** into the auth backend's Google provider configuration. The secret lives there, never in the app.
1. **Add every app redirect URL** (the custom scheme, and each web origin) to the auth backend's allowed-redirect list.

> **[RULE]**

> **The client secret never enters the repository or the binary.** It lives in the auth backend's configuration. If a setup guide tells you to put a client secret in your Flutter app, the guide is describing a different flow — one you should not use in a distributed mobile app, because the secret is extractable from every install.

> **[TRAP]**

> **Symptom: `redirect_uri_mismatch`, and the URI in the error is not one you recognise.** The URI in the error is the one your *backend* sent, not the one your app requested. Register that exact string — protocol, host, path, no trailing slash difference — in the Cloud Console. The two-hop structure (provider → backend → app) means there are two redirect lists to maintain and they contain different values.

<!-- chunk: auth.anon | tags: anonymous,identity,migration -->

## Anonymous accounts and the upgrade path

Sign the user in anonymously on first launch so every feature works immediately, and upgrade that same identity later — without ever minting a new one.

> **[RULE]**

> **Upgrading an anonymous account must preserve the user id. Never call `signUp`.** Use the link-identity or update-user flow. A fresh sign-up creates a new id, and every row the anonymous user created is instantly invisible to them under row-level security — their data is not deleted, it is orphaned, which is harder to explain and harder to recover.

> ```dart
> // WRONG — mints a new uid, orphans everything the user already created.
> await client.auth.signUp(email: email, password: password);
>
> // RIGHT — attaches credentials to the EXISTING anonymous identity.
> await client.auth.updateUser(UserAttributes(email: email, password: password));
> // or, for a social provider:
> await client.auth.linkIdentity(OAuthProvider.google, redirectTo: _redirect);
> ```

| Stage | User sees | Identity |
| --- | --- | --- |
| First launch | The app works. No sign-in wall. | Anonymous uid, created silently |
| Uses the app | Data saved locally and, if enabled, synced | Same uid; rows owned by it |
| Wants a second device | "Add an email or sign in with Google to use this on another device" | **Same uid**, now with credentials attached |
| Signs in on device 2 | Their data is there | Same uid, second session |

> **[WHY]**

> A sign-in wall on first launch is the largest single drop-off point in a utility app, and for most features it buys nothing — the app works fine with a local identity. Deferring the ask until the user wants something that genuinely requires it (a second device, a shared workspace, a receipt) converts far better, and the request finally has an honest justification attached to it.

> **[TRAP]**

> **Symptom: users on a second device see an empty app and assume sync is broken.** Anonymous identities are per-device by construction. Until the upgrade path exists, "cross-device sync" is not a feature you have — and if the UI implies otherwise, users will report data loss. Say plainly what the anonymous state does and does not give them.

<!-- chunk: auth.linking | tags: identity,account-management,ux -->

## Linked identities

An account can carry several identities — email, Google, others — and the user needs a screen that shows them and can add or remove one.

```dart
Future<List<LinkedIdentity>> linkedIdentities() async {
  final identities = _client.auth.currentUser?.identities ?? const [];
  return [
    for (final i in identities) (id: i.id, provider: i.provider),
  ];
}

Future<void> linkSocial(SocialProvider p) =>
    _client.auth.linkIdentity(_oauth(p), redirectTo: _redirect);

Future<void> unlink(LinkedIdentity identity) async {
  final all = await linkedIdentities();
  if (all.length <= 1) {
    throw const AuthException('cannot_unlink_last_identity');
  }
  await _client.auth.unlinkIdentity(/* … */);
}
```

> **[RULE]**

> **Never let a user unlink their last identity.** The account becomes unreachable — not deleted, just permanently inaccessible, with its rows intact and no way to authenticate to them. Check the count before unlinking and raise a named error the UI can localise. This is the account-level analogue of the last-owner protection in [page 07](07-supabase.html#invariants), and it deserves the same treatment: enforce it server-side too if the platform allows.

Render unknown providers gracefully. If an identity's provider id does not resolve through `fromWire`, show the raw id rather than hiding the row — a hidden identity the user cannot see is one they cannot remove.

<!-- chunk: auth.session | tags: session,tokens,storage -->

## Sessions, refresh and sign-out

| Concern | Practice |
| --- | --- |
| **Token storage** | Platform secure storage — Keystore on Android, Keychain on iOS/macOS. Most auth clients handle this; verify rather than assume, and never let tokens reach a plain key-value box. |
| **Refresh** | Handled by the client library. Your job is to react to the auth-state stream, not to schedule refreshes. |
| **Auth state as a provider** | Expose the auth-state change stream as a keep-alive provider; route guards and sync triggers watch it. Do not poll `currentUser`. |
| **Sign-out** | Clear the session *and* every cached view of that user's data. A stale cache after sign-out shows the previous user's rows to the next one — a confidentiality bug, not a cosmetic one. |
| **Session expiry mid-use** | Surface it as a specific state, not a generic error. "Your session expired, sign in again" is actionable; "something went wrong" sends the user to support. |
| **Desktop keychain** | macOS secure storage has its own failure mode — see [page 15](15-macos.html#keychain). |

> **[RULE]**

> **Sign-out must evict the cache.** Enumerate every cache prefix scoped to a user and clear it in the sign-out path. This is the same enumeration problem as [mutation invalidation](06-caching.html#invalidation) and it has the same countermeasure: list the prefixes in a comment next to the calls, and prefer over-eviction.

<!-- chunk: auth.pairing | tags: pairing,qr,onboarding -->

## Device pairing without an account

For an app that is deliberately account-optional, a QR handshake moves an identity to a second device without introducing a password.

The shape: device A renders a short-lived token as a QR code; device B scans it and exchanges it for the same identity. Requirements that make it safe rather than merely convenient:

- **Short expiry** — a minute or two. A QR photographed and used tomorrow is a credential leak.
- **Single use** — the token is consumed on redemption, server-side and atomically.
- **Server-generated, unguessable** — from an unambiguous alphabet so a user can also type it. Exclude visually confusable characters (`0`/`O`, `1`/`l`/`I`); one project uses a 32-letter alphabet and a 10-character code.
- **Visible on both sides** — device A should show that a pairing occurred, so an unexpected one is noticed.

The same primitive covers invitations to a shared tenant: a single-use personal invitation is a pairing token with a target. See [page 11](11-barcode-qr.html) for generating and scanning the code itself.

<!-- chunk: auth.testing | tags: testing,auth,fakes -->

## Testing an auth layer

Fake the repository, not the network — and make the fake enforce the same rules the server does.

```dart
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.user, List<LinkedIdentity>? identities})
      : _identities = identities ?? const [];

  AppUser? user;
  List<LinkedIdentity> _identities;
  final _controller = StreamController<AppUser?>.broadcast();

  @override
  Stream<AppUser?> get authState => _controller.stream;

  @override
  Future<void> upgradeAnonymous({required String email}) async {
    // Mirrors the real rule: the uid MUST NOT change.
    user = user?.copyWith(email: email);
    _controller.add(user);
  }

  @override
  Future<void> unlink(LinkedIdentity i) async {
    // Mirrors the server-side invariant, so a widget test cannot pass
    // against behaviour the real backend refuses.
    if (_identities.length <= 1) {
      throw const AuthException('cannot_unlink_last_identity');
    }
    _identities = [..._identities]..remove(i);
  }
}
```

> **[RULE]**

> **The fake must enforce every invariant the server enforces.** A permissive fake produces green widget tests for flows that fail in production — the last-identity unlink, the row a non-owner cannot see, the quota that is already exhausted. This is [the false-green failure](03-tdd-and-testing.html#false-green) in its most expensive form, because auth bugs are discovered by users rather than by monitoring.

Cases worth an explicit test each: anonymous first launch creates an identity; upgrade preserves the uid; sign-out clears cached user data; an expired session surfaces the specific state; unlinking the last identity is refused; and an unrecognised provider id still renders.

> **[CHECK]**

> The manual test that catches the most: sign in on device A, create data, upgrade to a permanent identity, sign in on device B, and confirm the data is there. Then sign out on B and confirm nothing of A's remains visible. Both halves — the second is the one people skip.

#### Sources for this page

- One project's auth feature: the `SocialProvider` enum with its retired-provider rationale, the `kIsWeb` redirect resolution, the linked-accounts screen, and the browser-OAuth-no-SDK decision recorded against its no-proprietary-services constraint.
- The other project's cross-device sync work: the anonymous-per-device identity model, the requirement that an anonymous-to-permanent upgrade preserve the uid rather than calling `signUp`, and the QR device-pairing design.
- Both projects' invite-code conventions (server-generated, unambiguous alphabet, single-use).

The Google Cloud Console steps are standard provider configuration, stated here because the "Web application client, not Android client" point is the one most commonly gotten wrong with browser-delegated flows. The fake-repository code is illustrative.
