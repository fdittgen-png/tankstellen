// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:tankstellen/core/sync/trip_share_transport.dart';

/// One recorded [FakeTripShareTransport.rpc] call.
class RpcCall {
  final String fn;
  final Map<String, dynamic> params;
  RpcCall(this.fn, this.params);
}

/// One recorded [FakeTripShareTransport.upsertShare] call.
class ShareUpsertCall {
  final Map<String, dynamic> row;
  final String onConflict;
  ShareUpsertCall(this.row, this.onConflict);
}

/// In-memory [TripShareTransport] for unit tests (#3747), mirroring the
/// [FakeSyncTransport] pattern: canned per-function RPC responses (or
/// errors), recorded calls, and an upsert failure flag.
class FakeTripShareTransport implements TripShareTransport {
  @override
  String userId;

  /// RPC function name → canned response. A value that is an [Object]
  /// implementing [Exception]/[Error] (or any object placed in
  /// [rpcErrors]) is THROWN instead.
  final Map<String, dynamic> rpcResults;

  /// RPC function name → error to throw (takes precedence over
  /// [rpcResults]).
  final Map<String, Object> rpcErrors;

  final List<RpcCall> rpcCalls = [];
  final List<ShareUpsertCall> upsertCalls = [];

  bool failUpserts = false;

  FakeTripShareTransport({
    this.userId = 'owner-1',
    Map<String, dynamic>? rpcResults,
    Map<String, Object>? rpcErrors,
  })  : rpcResults = rpcResults ?? {},
        rpcErrors = rpcErrors ?? {};

  @override
  Future<dynamic> rpc(String fn, Map<String, dynamic> params) {
    rpcCalls.add(RpcCall(fn, params));
    final error = rpcErrors[fn];
    if (error != null) return Future<dynamic>.error(error);
    return Future<dynamic>.value(rpcResults[fn]);
  }

  @override
  Future<void> upsertShare(
    Map<String, dynamic> row, {
    required String onConflict,
  }) {
    if (failUpserts) {
      return Future<void>.error(Exception('FakeTripShareTransport: offline'));
    }
    upsertCalls.add(ShareUpsertCall(row, onConflict));
    return Future<void>.value();
  }
}
