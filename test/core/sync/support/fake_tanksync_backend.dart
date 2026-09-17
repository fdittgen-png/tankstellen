// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tankstellen/core/sync/tanksync_sdk.dart';

/// One Supabase project on the fake network: its accounts and the rows the
/// app wrote. Shared by every [FakeTankSyncBackend] "process" on the same
/// device, so a relaunch finds the server as the killed process left it.
class FakeSupabaseProject {
  FakeSupabaseProject(this.host);

  final String host;

  /// Refresh tokens the server still honours → the user id they belong to.
  final Map<String, String> refreshTokens = {};

  /// Email accounts: address → user id (`grant_type=password`).
  final Map<String, String> emailAccounts = {};

  /// Every table write (`users` upserts included), by table name.
  final List<String> writes = [];

  int _seq = 0;

  /// The next anonymous user id [signup] mints.
  String mintUserId() => '$host-user-${++_seq}';
}

/// A fake TankSync backend behind the REAL Supabase client (#4162).
///
/// It models what `TankSyncClient` depends on and the SDK hides:
///
/// * **SDK initialised** — like `Supabase.initialize`, a second
///   [initialize] is skipped while a client is live, whatever its URL
///   ([skippedInitializeCalls]);
/// * **URL** — every request lands in [requests]; [hostsContacted] says
///   which server the app actually talked to;
/// * **session** — gotrue runs for real over a mock HTTP client:
///   anonymous sign-up, the `users` upsert, sign-out, and a persisted
///   session in the device [keychain] restored on the next initialize,
///   the way `SupabaseAuth` does it;
/// * **refresh failure** — [rejectRefreshTokens] makes the server reject
///   the next refresh non-retryably, so gotrue removes the session and
///   emits `signedOut(sessionExpired)`; [networkDown] makes every request
///   fail with a socket error, [hang] parks every request until released.
///
/// Driving the real client is deliberate: a fake that answered "signed in"
/// itself would only prove what the fake was told.
class FakeTankSyncBackend implements TankSyncSdk {
  FakeTankSyncBackend({
    Map<String, String>? keychain,
    Map<String, FakeSupabaseProject>? projects,
  })  : keychain = keychain ?? {},
        projects = projects ?? {};

  /// The device keychain the SDK persists sessions in — survives a kill.
  final Map<String, String> keychain;

  /// The servers, by host — survive a kill too.
  final Map<String, FakeSupabaseProject> projects;

  /// Every request, in order.
  final List<Uri> requests = [];

  int initializeCalls = 0;
  int skippedInitializeCalls = 0;
  int disposeCalls = 0;

  /// The server rejects refresh tokens (non-retryable).
  bool rejectRefreshTokens = false;

  /// Every request fails with a socket error (retryable).
  bool networkDown = false;

  /// While non-null, every request waits for it.
  Completer<void>? hang;

  SupabaseClient? _client;
  String? _host;
  String? _persistKey;
  StreamSubscription<AuthState>? _persistence;

  Set<String> get hostsContacted => {for (final u in requests) u.host};

  FakeSupabaseProject project(String host) =>
      projects.putIfAbsent(host, () => FakeSupabaseProject(host));

  /// The same device and servers, as a new process sees them.
  FakeTankSyncBackend relaunched() =>
      FakeTankSyncBackend(keychain: keychain, projects: projects);

  @override
  bool get isInitialized => _client != null;

  @override
  String? get host => _host;

  @override
  SupabaseClient get client {
    final c = _client;
    if (c == null) {
      throw StateError('Supabase is not initialised (fake)');
    }
    return c;
  }

  @override
  Future<void> initialize({
    required String url,
    required String publishableKey,
    required String persistSessionKey,
  }) async {
    initializeCalls++;
    if (_client != null) {
      skippedInitializeCalls++;
      return;
    }
    final host = Uri.parse(url).host.toLowerCase();
    final c = SupabaseClient(
      url,
      publishableKey,
      httpClient: MockClient(_handle),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    _client = c;
    _host = host;
    _persistKey = persistSessionKey;
    // SupabaseAuth's persistence: a session is written on every change and
    // removed on sign-out.
    _persistence = c.auth.onAuthStateChange.listen((state) {
      final session = state.session;
      if (session != null) {
        keychain[persistSessionKey] = jsonEncode(session.toJson());
      } else if (state.event == AuthChangeEvent.signedOut) {
        keychain.remove(persistSessionKey);
      }
    }, onError: (Object _) {});
    final persisted = keychain[persistSessionKey];
    if (persisted != null) {
      try {
        await c.auth.setInitialSession(persisted);
      } catch (_) {
        // SupabaseAuth logs and carries on without a session.
      }
    }
  }

  @override
  Future<void> dispose() async {
    final c = _client;
    if (c == null) return;
    disposeCalls++;
    _client = null;
    _host = null;
    await _persistence?.cancel();
    _persistence = null;
    await c.dispose();
  }

  /// What the SDK's auto-refresh ticker does when the access token is due:
  /// refresh it — if a client is still live to tick.
  Future<void> autoRefreshTick() async {
    final c = _client;
    if (c == null || c.auth.currentSession == null) return;
    try {
      await c.auth.refreshSession();
    } catch (_) {
      // The SDK reports the outcome on the auth stream.
    }
  }

  /// The persisted session key of the live (or last) client.
  String? get persistSessionKey => _persistKey;

  Future<http.Response> _handle(http.Request req) async {
    requests.add(req.url);
    final pending = hang;
    if (pending != null) await pending.future;
    if (networkDown) throw const SocketException('network is down (fake)');
    final project = this.project(req.url.host);
    final path = req.url.path;
    if (path.endsWith('/auth/v1/signup')) {
      return _json(req, _session(project, project.mintUserId()));
    }
    if (path.endsWith('/auth/v1/token') &&
        req.url.queryParameters['grant_type'] == 'password') {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      final userId = project.emailAccounts[body['email']];
      if (userId == null) {
        return _json(
          req,
          {'code': 400, 'error_code': 'invalid_credentials', 'msg': 'no'},
          status: 400,
        );
      }
      return _json(req, _session(project, userId, email: body['email'] as String));
    }
    if (path.endsWith('/auth/v1/token')) {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      final token = body['refresh_token'] as String?;
      final userId = project.refreshTokens.remove(token);
      if (rejectRefreshTokens || userId == null) {
        return _json(
          req,
          {
            'code': 400,
            'error_code': 'refresh_token_not_found',
            'msg': 'Invalid Refresh Token: Refresh Token Not Found',
          },
          status: 400,
        );
      }
      return _json(req, _session(project, userId));
    }
    if (path.endsWith('/auth/v1/logout')) {
      return http.Response('', 204, request: req);
    }
    if (path.contains('/rest/v1/')) {
      final table = path.split('/rest/v1/').last;
      if (req.method != 'GET') project.writes.add(table);
      return _json(req, <Object>[], status: req.method == 'GET' ? 200 : 201);
    }
    return _json(req, <String, Object>{});
  }

  static int _tokenSeq = 0;

  Map<String, dynamic> _session(
    FakeSupabaseProject project,
    String userId, {
    String? email,
  }) {
    final refresh = 'rt-${++_tokenSeq}';
    project.refreshTokens[refresh] = userId;
    return {
      'access_token': 'at-$_tokenSeq',
      'token_type': 'bearer',
      'expires_in': 3600,
      // Far future: a restored session is valid without a refresh.
      'expires_at': 4102444800,
      'refresh_token': refresh,
      'user': {
        'id': userId,
        'aud': 'authenticated',
        'role': 'authenticated',
        'created_at': '2026-01-01T00:00:00Z',
        'app_metadata': <String, Object>{},
        'user_metadata': <String, Object>{},
        'email': ?email,
        'is_anonymous': email == null,
      },
    };
  }

  static http.Response _json(http.Request req, Object body,
          {int status = 200}) =>
      http.Response(jsonEncode(body), status,
          request: req, headers: {'content-type': 'application/json'});
}
