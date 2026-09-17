// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Where a TankSync session stands, derived from the flags that hold it
/// (#4162).
///
/// TankSync has no single state value. What the app is doing with the
/// user's cloud identity is spread over the persisted settings
/// (`sync_enabled`, `consent_cloud_sync`, the credentials, `sync_user_id`),
/// two "initialised" flags (the app's and the SDK's, which can disagree),
/// the SDK's live session, the relink flag on `SyncConfig`, the init
/// in-flight count and the retry ladder. Ten facts describe hundreds of
/// combinations; about eight are meant to exist. This file writes down
/// which, as a phase DERIVED from the facts — the facts stay the storage,
/// so naming the phases changes no behaviour.
enum TankSyncSessionPhase {
  /// Sync is not set up: `sync_enabled` is off or the credentials are gone.
  off,

  /// Set up and consented, but no client is live and nothing is trying to
  /// build one — before the launch init, after a sign-out, or once the
  /// retry ladder ran out (a hidden sub-state, see the table doc).
  configured,

  /// A `TankSyncInit.run` pass is in flight.
  initializing,

  /// The client is live and a user session exists: passes can sync.
  ready,

  /// The client is live but the session is gone, and nobody has flagged
  /// it for re-linking yet.
  sessionLost,

  /// A stored identity has no session; the sync settings show re-link
  /// guidance (#3449).
  relinkRequired,

  /// The launch init failed and the #3450 retry ladder is armed.
  initFailed,

  /// Sync is set up but the Cloud Sync consent is withdrawn (#3866).
  consentWithdrawn,
}

/// The facts [phaseOf] reads — one snapshot of everything that holds a
/// TankSync session's state (#4162).
class SessionFacts {
  const SessionFacts({
    this.syncEnabled = false,
    this.consent = false,
    this.hasCredentials = false,
    this.configuredHost,
    this.clientInitialized = false,
    this.sdkInitialized = false,
    this.sdkHost,
    this.backendHost,
    this.sessionUserId,
    this.storedUserId,
    this.relinkFlag = false,
    this.configEnabled = false,
    this.initInFlight = false,
    this.retryPending = false,
  });

  /// `sync_enabled` in settings.
  final bool syncEnabled;

  /// `consent_cloud_sync` in settings.
  final bool consent;

  /// Both the Supabase URL and the anon key are stored.
  final bool hasCredentials;

  /// Host of the stored Supabase URL, lower-cased; null when none.
  final String? configuredHost;

  /// `TankSyncClient`'s own initialised flag.
  final bool clientInitialized;

  /// Whether the Supabase SDK singleton is initialised — which the app
  /// flag above does not always agree with.
  final bool sdkInitialized;

  /// Host the SDK's client actually talks to; null when not initialised.
  final String? sdkHost;

  /// Host `TankSyncClient` believes it connected to (#4047).
  final String? backendHost;

  /// The SDK's current user id; null when there is no session.
  final String? sessionUserId;

  /// `sync_user_id` in settings.
  final String? storedUserId;

  /// `SyncConfig.relinkRequired`, as last published.
  final bool relinkFlag;

  /// `SyncConfig.enabled`, as last published.
  final bool configEnabled;

  /// A `TankSyncInit.run` pass has started and not finished.
  final bool initInFlight;

  /// The #3450 retry ladder is armed.
  final bool retryPending;

  bool get _sessionLive => clientInitialized && sessionUserId != null;

  @override
  String toString() => 'SessionFacts(enabled=$syncEnabled consent=$consent '
      'creds=$hasCredentials client=$clientInitialized sdk=$sdkInitialized '
      'sdkHost=$sdkHost backendHost=$backendHost configuredHost=$configuredHost '
      'session=${sessionUserId != null} stored=${storedUserId != null} '
      'relink=$relinkFlag configEnabled=$configEnabled '
      'inFlight=$initInFlight retry=$retryPending)';
}

/// The phase [facts] describe. Total: every combination maps to a phase,
/// so a combination nobody expected is still a phase, never a crash.
///
/// Precedence, and why:
///
/// * `off` first — nothing is set up, so nothing else is meaningful;
/// * `consentWithdrawn` next — without consent no other phase may act;
/// * `ready` before the in-flight check — a live session is the truth even
///   while a second, abandoned init is still running (#3450);
/// * `initializing` before `relinkRequired` — the launch guard decides
///   relinking at the END of its pass;
/// * `relinkRequired` needs no live client: the flag outlives a sign-out;
/// * `initFailed` before `sessionLost` — a launch pass that built the
///   client but could not sign in leaves a live client without a session,
///   and what describes it is the armed ladder, not a lost session.
TankSyncSessionPhase phaseOf(SessionFacts facts) {
  if (!facts.syncEnabled || !facts.hasCredentials) {
    return TankSyncSessionPhase.off;
  }
  if (!facts.consent) return TankSyncSessionPhase.consentWithdrawn;
  if (facts._sessionLive) return TankSyncSessionPhase.ready;
  if (facts.initInFlight) return TankSyncSessionPhase.initializing;
  if (facts.relinkFlag) return TankSyncSessionPhase.relinkRequired;
  if (facts.retryPending) return TankSyncSessionPhase.initFailed;
  if (facts.clientInitialized) return TankSyncSessionPhase.sessionLost;
  return TankSyncSessionPhase.configured;
}

/// Every phase change a TankSync session is allowed to make (#4162).
///
/// Each edge is here because of a named writer:
///
/// * `off → ready` — `SyncState.connect` (the setup screen) writes the
///   settings after its client is signed in. `off → configured` — the
///   same settings written by a path that builds no client (the legacy
///   wizard's email branch before its init).
/// * `configured → initializing` — the launch init or a retry starts.
///   `configured → sessionLost` — `switchToAnonymous` re-initialises the
///   client before it signs in. `configured → ready` — the same re-init
///   when the SDK restored a session. `configured → initFailed` — the
///   launch arms the #3450 ladder after a failed pass.
///   `configured → relinkRequired` — the launch marks #3449's flag.
/// * `initializing → ready` (a session was restored or minted),
///   `→ sessionLost` (the #3449 guard found a stored id and no session;
///   the flag follows), `→ configured` (the pass threw; the ladder is
///   armed next), `→ initFailed` (a retry attempt failed with the ladder
///   still armed).
/// * `ready → configured` — `TankSyncClient.signOut` (disconnect, start
///   fresh, account deletion, the #3164 failed `users` upsert).
///   `ready → relinkRequired` — the SDK dropped the session on a rejected
///   refresh token and the owner flagged it (#4338).
/// * `sessionLost → ready` (a sign-in), `→ relinkRequired` (the launch
///   guard's flag), `→ configured` (a sign-out), `→ initFailed` (the
///   launch arms the ladder after a pass that built the client but could
///   not sign in).
/// * `relinkRequired → ready` (email sign-in re-links, or start fresh),
///   `→ configured` (start fresh signs the dead client out first).
/// * `initFailed → initializing` (the ladder or a resume fires),
///   `→ ready` (the abandoned first pass finished after all),
///   `→ configured | sessionLost` (the ladder gave up, with or without a
///   built client — a hidden sub-state: nothing retries until the next
///   launch).
/// * `consentWithdrawn → configured | initializing | ready |
///   relinkRequired` — the consent is granted again and the stored
///   identity resumes (or is found to need re-linking).
/// * Every phase but `off` → `consentWithdrawn` (the consent is withdrawn)
///   and → `off` (disconnect clears the settings).
///
/// A write that keeps the phase is not a transition and is always allowed.
///
/// ## Hidden sub-states (deliberately not phases)
///
/// * the ladder exhausted after a failed launch reads `configured` (no
///   client was built) or `sessionLost` (the client was built, the
///   sign-in never succeeded);
/// * `initializing` with a retry armed: the first pass timed out at 8 s
///   and is still running while the ladder waits (#3450);
/// * `ready` with a stale `relinkRequired` flag between an email sign-in
///   and the provider state that clears it.
const Map<TankSyncSessionPhase, Set<TankSyncSessionPhase>>
    kTankSyncSessionTransitions = {
  TankSyncSessionPhase.off: {
    TankSyncSessionPhase.ready,
    TankSyncSessionPhase.configured,
  },
  TankSyncSessionPhase.configured: {
    TankSyncSessionPhase.initializing,
    TankSyncSessionPhase.sessionLost,
    TankSyncSessionPhase.ready,
    TankSyncSessionPhase.initFailed,
    TankSyncSessionPhase.relinkRequired,
    TankSyncSessionPhase.consentWithdrawn,
    TankSyncSessionPhase.off,
  },
  TankSyncSessionPhase.initializing: {
    TankSyncSessionPhase.ready,
    TankSyncSessionPhase.sessionLost,
    TankSyncSessionPhase.configured,
    TankSyncSessionPhase.initFailed,
    TankSyncSessionPhase.consentWithdrawn,
    TankSyncSessionPhase.off,
  },
  TankSyncSessionPhase.ready: {
    TankSyncSessionPhase.configured,
    TankSyncSessionPhase.relinkRequired,
    TankSyncSessionPhase.consentWithdrawn,
    TankSyncSessionPhase.off,
  },
  TankSyncSessionPhase.sessionLost: {
    TankSyncSessionPhase.ready,
    TankSyncSessionPhase.relinkRequired,
    TankSyncSessionPhase.configured,
    TankSyncSessionPhase.initFailed,
    TankSyncSessionPhase.consentWithdrawn,
    TankSyncSessionPhase.off,
  },
  TankSyncSessionPhase.relinkRequired: {
    TankSyncSessionPhase.ready,
    TankSyncSessionPhase.configured,
    TankSyncSessionPhase.consentWithdrawn,
    TankSyncSessionPhase.off,
  },
  TankSyncSessionPhase.initFailed: {
    TankSyncSessionPhase.initializing,
    TankSyncSessionPhase.ready,
    TankSyncSessionPhase.configured,
    TankSyncSessionPhase.sessionLost,
    TankSyncSessionPhase.consentWithdrawn,
    TankSyncSessionPhase.off,
  },
  TankSyncSessionPhase.consentWithdrawn: {
    TankSyncSessionPhase.configured,
    TankSyncSessionPhase.initializing,
    TankSyncSessionPhase.ready,
    TankSyncSessionPhase.relinkRequired,
    TankSyncSessionPhase.off,
  },
};

/// Whether moving from [from] to [to] is a documented transition — or no
/// transition at all.
bool isTankSyncSessionTransition(
  TankSyncSessionPhase from,
  TankSyncSessionPhase to,
) =>
    from == to || (kTankSyncSessionTransitions[from]?.contains(to) ?? false);

/// A property every observed [SessionFacts] must have, whatever its phase
/// (#4162). A snapshot that breaks one is recorded as the invariant it
/// breaks, and no edge is measured from or to it: its phase describes
/// flags that should not coexist, so the edge would be noise.
enum SessionInvariant {
  /// A live client talks to the backend the app believes it connected
  /// to, and that backend is the configured one. Broken when a second
  /// `Supabase.initialize` was skipped by the SDK and the old client
  /// stayed live (#4336).
  clientMatchesBackend,

  /// Nothing reaches the cloud without the Cloud Sync consent: no
  /// published `SyncConfig.enabled`, no signed-in live client (#4337,
  /// GDPR Art. 7(3)).
  noCloudWithoutConsent;

  /// Whether [facts] satisfy this invariant.
  bool holdsFor(SessionFacts facts) => switch (this) {
        clientMatchesBackend => !facts.clientInitialized ||
            (facts.sdkInitialized &&
                facts.sdkHost == facts.backendHost &&
                (facts.configuredHost == null ||
                    !facts.syncEnabled ||
                    facts.configuredHost == facts.sdkHost)),
        noCloudWithoutConsent =>
          facts.consent || (!facts.configEnabled && !facts._sessionLive),
      };
}
