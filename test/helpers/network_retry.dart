// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart' show TestFailure;

/// Bounded retry for the `network`-tagged nightly suite (#3096).
///
/// The live API-connectivity / search tests hit real upstream endpoints
/// (Italy MIMIT, Denmark OK, …) which intermittently TIME OUT or return a
/// transient 5xx. Those blips filed a `nightly-flaky` issue every few nights
/// even though nothing in the app or the upstream contract was broken. These
/// helpers retry ONLY transient transport failures a couple of times, so a
/// blip self-heals — while a GENUINE, persistent breakage (every attempt
/// fails, or the upstream contract changed → an assertion fails) still fails
/// hard, preserving the whole point of the live suite.

bool _isTransient(DioException e) =>
    e.type == DioExceptionType.connectionTimeout ||
    e.type == DioExceptionType.receiveTimeout ||
    e.type == DioExceptionType.sendTimeout ||
    e.type == DioExceptionType.connectionError ||
    // TLS handshake blips (#3115/#3222): during an upstream certificate
    // rotation, load-balancer backends can briefly serve inconsistent /
    // incomplete chains. A retry draws again; a PERSISTENTLY broken TLS
    // endpoint still exhausts the bounded retries and fails hard.
    e.error is HandshakeException ||
    (e.response?.statusCode != null && e.response!.statusCode! >= 500);

/// ISRG "Root YR" — Let's Encrypt's 2026 root, embedded as an EXTRA trust
/// anchor for the nightly network suite (#3115/#3222).
///
/// On 2026-06-09 the Denmark OK endpoint (`mobility-prices.ok.dk`) renewed
/// onto the new Let's Encrypt `YR1` intermediate, and the nightly Linux
/// runner started failing its handshake with `CERTIFICATE_VERIFY_FAILED:
/// unable to get local issuer certificate`: the Ubuntu image's
/// `ca-certificates` bundle predates ISRG Root YR, dart:io/BoringSSL does no
/// AIA chasing (unlike macOS/iOS), and during the rotation window the server
/// did not yet serve the `Root YR ← ISRG Root X1` cross-sign that would have
/// bridged the gap. Trusting the genuine Root YR root — which current
/// platform stores ship — makes the suite verify exactly like an up-to-date
/// device, WITHOUT weakening any real signal: an expired / revoked /
/// wrong-host certificate still fails.
///
/// Provenance (verified 2026-06-11 against the live mobility-prices.ok.dk
/// chain — the SPKI matches the served `Root YR by X1` cross-sign and this
/// root verifies the served `YR1` intermediate):
///   - source: https://letsencrypt.org/certs/gen-y/root-yr.pem
///   - subject: C=US, O=ISRG, CN=Root YR (self-signed)
///   - validity: 2025-09-03 → 2045-09-02
///   - SPKI SHA-256:
///     7e4e8838a8add6295de7ae3b047d3aba3488ab95db0a0aa56d897a00d8618bcf
///
/// Remove once GitHub's ubuntu-latest `ca-certificates` ships ISRG Root YR.
const String _isrgRootYrPem = '''
-----BEGIN CERTIFICATE-----
MIIFKTCCAxGgAwIBAgIRAOxGNJNgz0sP+KmC2Tqpyj0wDQYJKoZIhvcNAQELBQAw
LjELMAkGA1UEBhMCVVMxDTALBgNVBAoTBElTUkcxEDAOBgNVBAMTB1Jvb3QgWVIw
HhcNMjUwOTAzMDAwMDAwWhcNNDUwOTAyMjM1OTU5WjAuMQswCQYDVQQGEwJVUzEN
MAsGA1UEChMESVNSRzEQMA4GA1UEAxMHUm9vdCBZUjCCAiIwDQYJKoZIhvcNAQEB
BQADggIPADCCAgoCggIBANvGJnN78CTJdWL3+eGfsLN5TrNBJs+VH9hRXqRbwxu9
sGNiB0BD1fcOxbSUQCJIM1xE13Db+5Cw1w0s0EBYsvuIP/6joF0w8cuImbgR1OGg
YbSQ4OpzI+DG8SGuTlcE873OCS+kh3srlo6vl43M5OJg4Aeo1sfHp6kTJDoIiFBN
JAY+OKfX/FUvYKuhjT+no49lmqmupSBI5PkBQiqrEGtWU5uxU/cQWHGu8jSjFBzn
ZqvbNPLMXMLFxCb3WTfrJBXXjqvWG+v4bjzxjjeAtOlU7qarRDvNOyAuQYLln904
M+faKx8hnLCpJ15ZqaEgcNlY+9MMWcC5yvL2A2j3l9+2buggZX+dOE91zYmIdawT
vSZuVvlbRrAlLxIB6pwMBjneXCjYQ8+3BCCjssbSNpZU3hTcBDdhfAlEDlYr6pEa
tnMdmDT5BqnKC92bd0EhM1fbLHioLccLCuievT8ZkPhZrq7Mii7gNXAcUEAR8+lz
Yal+9zTg7C5DALyVOeG/CqfRAMn1KSHCR0NSA6P8tn/mGRlnCct5rtVCLnVySVpU
6H1qGg3DgTOuskf8eahTMiYbI5ezPJmO5ertalskQ1utp74+eDy92PI4ftHKTbq9
IWhH4YZKh3WnJEIt+oQvlYZbY8tpEroKrFB6PFGzrJIDRyts4HqvuH52RFj2zv/B
AgMBAAGjQjBAMA4GA1UdDwEB/wQEAwIBBjAPBgNVHRMBAf8EBTADAQH/MB0GA1Ud
DgQWBBTe51tg0CJtQCh9Pw0B/qS1UrRRlDANBgkqhkiG9w0BAQsFAAOCAgEAWHnf
713Bdkq7t5yN2dNIgQakUb94X9WuyhMEHHkgx4oDpSUlnG0w4g94MoqaEUE31ZjR
LU7L5LD1g9ujFHTQu8AD215AHMVQFbm6j8hQxdXHAzDajFNQnOlDJrLjzIx176oy
AjvUtejZx2NNmdb5fd0WGVGsCdoAJ3N8ozo7ajE8t6vfxStZb4BQ9WYJGHUDrv2N
i5tJF6CNiPnlzs3BUfECRbE4JSk+jvy8+VoGiFE8qsH/j78x2fjgQhAQFV7P7Zxy
dBTZ1wEkNpZNW2qnaK1SKBLa+xf6E06YRIq5uaI+HWH8SY1y5VbRgzq40EKg3yxP
06fz+uYAUIFJoLNfhwRCc3Q6pQVuMX3yAjHAes4gk4moGcLQ5p7HAh39yeylZc1J
41sx/jKwLIkPE6Rr1Nf4pxdsxf9SA4yOEiAkDgq04DVxn8hgYFdUtBCuiuVC2heA
EiqVEa+8QZjuw8Gj0EbHXcRd1nInvGqRS1o9Is7YBdQN57X1AYveGBNNqjICSb7c
awuw1EawTDrs13VUlJVEsbQ0/O/1aaV73mCdOQ8azqL2KTv1Ewu1xbquE2S+kdQU
To9TUwat3wUA6cwXh1EfpS/3fJ0aGah5hdpRyoCLDlsSn8tkrjMfFFX0viC+GxHc
sI1ANRYvqSFC2X1VRZfDg+wD6E21BccmifG4yWc=
-----END CERTIFICATE-----
''';

/// System trust roots + the pinned [_isrgRootYrPem] (#3115/#3222).
///
/// Used by [retryingDio] so the nightly network suite validates upstream TLS
/// the way an UP-TO-DATE platform store does, instead of the runner image's
/// (potentially months-old) `ca-certificates` bundle.
SecurityContext networkTestSecurityContext() =>
    SecurityContext(withTrustedRoots: true)
      ..setTrustedCertificatesBytes(utf8.encode(_isrgRootYrPem));

class _RetryInterceptor extends Interceptor {
  _RetryInterceptor(this._dio, {this.maxRetries = 2});

  static const _baseDelay = Duration(seconds: 2);

  final Dio _dio;
  final int maxRetries;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final attempt = (err.requestOptions.extra['retry_attempt'] as int?) ?? 0;
    if (_isTransient(err) && attempt < maxRetries) {
      await Future<void>.delayed(_baseDelay * (attempt + 1));
      final opts = err.requestOptions..extra['retry_attempt'] = attempt + 1;
      try {
        return handler.resolve(await _dio.fetch<dynamic>(opts));
      } catch (_) {
        return handler.next(err);
      }
    }
    return handler.next(err);
  }
}

/// A [Dio] that transparently retries transient transport failures (#3096).
/// Drop-in for `Dio(BaseOptions(...))` in the live network tests.
Dio retryingDio(BaseOptions options, {int maxRetries = 2}) {
  final dio = Dio(options);
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () => HttpClient(context: networkTestSecurityContext()),
  );
  dio.interceptors.add(_RetryInterceptor(dio, maxRetries: maxRetries));
  return dio;
}

/// Retry [body] up to [attempts] times on a transient [DioException] (#3096),
/// for live tests that go through a SERVICE (which owns its own Dio) rather
/// than a raw [Dio]. A [TestFailure] (a real assertion) is NEVER retried — it
/// rethrows immediately so a genuine contract break fails fast.
Future<T> retryNetwork<T>(
  Future<T> Function() body, {
  int attempts = 3,
  Duration baseDelay = const Duration(seconds: 2),
}) async {
  Object? lastError;
  StackTrace? lastStack;
  for (var i = 0; i < attempts; i++) {
    try {
      return await body();
    } on TestFailure {
      rethrow;
    } catch (e, st) {
      if (e is DioException && !_isTransient(e)) rethrow;
      lastError = e;
      lastStack = st;
      if (i < attempts - 1) await Future<void>.delayed(baseDelay * (i + 1));
    }
  }
  Error.throwWithStackTrace(lastError!, lastStack!);
}
