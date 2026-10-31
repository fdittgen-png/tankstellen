// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// Only composition-owned trace records/bundles may preserve their bare `id`.
enum DiagnosticScope { unknown, trace, bundle }

/// Semantic field decisions used by PiiScrubber; unknown supplier maps do not
/// become trusted trace records merely by naming a field `id` or `where`.
class DiagnosticFieldPolicy {
  DiagnosticFieldPolicy._();
  static final _symbol = RegExp(r'^[A-Za-z_$][A-Za-z0-9_.$]*$');
  static final _uuid = RegExp(
    r'^[a-fA-F0-9]{8}(?:-[a-fA-F0-9]{4}){3}-[a-fA-F0-9]{12}$',
  );
  static final _artifact = RegExp(r'^[a-fA-F0-9]{7,64}$');
  static final _qualifiedSymbol = RegExp(
    r'^(?:[A-Z][A-Za-z0-9_$]+\.)+[a-z_$][A-Za-z0-9_$]*$',
  );
  static const _privateFields = {
    'lat',
    'latitude',
    'lng',
    'lon',
    'longitude',
    'mac',
    'device',
    'devices',
    'deviceid',
    'adapter',
    'adapters',
    'adapterid',
    'requestedmac',
    'redactedmac',
    'adaptermac',
    'deviceaddress',
    'adapteraddress',
    'adaptername',
    'devicename',
    'vin',
    'vintail',
    'activeprofileid',
    'activeprofilename',
    'profileid',
    'profilename',
    'user',
    'profile',
    'userdata',
    'userid',
    'username',
    'account',
    'accounts',
    'accountid',
    'email',
    'address',
    'phone',
    'phonenumber',
    'apikey',
    'accesstoken',
    'refreshtoken',
    'authorization',
    'auth',
    'token',
    'credential',
    'credentials',
    'sessionid',
    'password',
    'secret',
    'receipt',
    'receipts',
    'receiptid',
    'receiptnumber',
    'receipttext',
    'ocrtext',
    'ocrresult',
    'ocrresults',
  };
  static const _buildFields = {
    'sourcesha',
    'sourcecommit',
    'gitsha',
    'buildid',
    'nativebuildid',
  };
  static const _incidentFields = {'incidentid', 'attemptid', 'runid'};
  static const _knownSymbols = {'already_connected_to_device'};
  // SyncPassOutcome's long serialized enum names (#4477). These are known
  // dispositions, not an exemption for arbitrary long reason/where values.
  static const _syncOutcomes = {
    'completedWithTimeouts',
    'completedUnauthenticated',
    'skippedAlreadyRunning',
    'skippedNothingRegistered',
  };

  static String _key(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  static bool privateField(List<String> path) =>
      path.isNotEmpty && _privateFields.contains(_key(path.last));
  static bool artifact(String value) =>
      _artifact.hasMatch(value) || _uuid.hasMatch(value);
  static bool schemaKey(String key) =>
      _symbol.hasMatch(key) &&
      !artifact(key) &&
      (key.length < 20 || key == 'transportDecisionReason');

  static bool preserve(List<String> path, String value, DiagnosticScope scope) {
    if (path.isEmpty) return false;
    final field = _key(path.last);
    if (_buildFields.contains(field) && _artifact.hasMatch(value)) return true;
    if (_incidentFields.contains(field) && _uuid.hasMatch(value)) return true;
    if (_knownSymbols.contains(value) &&
        (field == 'reason' || field == 'transportdecisionreason')) {
      return true;
    }
    if (_syncOutcomes.contains(value) &&
        (field == 'outcome' || field == 'reason')) {
      return true;
    }
    if (field == 'sourcesymbol' && _qualifiedSymbol.hasMatch(value)) {
      return true;
    }
    final tracePath = scope == DiagnosticScope.trace
        ? path
        : scope == DiagnosticScope.bundle &&
              path.length >= 3 &&
              path[0] == 'traces' &&
              path[1] == '*'
        ? path.sublist(2)
        : const <String>[];
    if (tracePath.isEmpty) return false;
    if (tracePath.length == 1 && field == 'id') return _uuid.hasMatch(value);
    if (field == 'errortype' && _symbol.hasMatch(value)) {
      return tracePath.length == 1 ||
          tracePath.join('.') == 'serviceChainState.attempts.*.errorType';
    }
    return tracePath.length == 3 &&
        tracePath[0] == 'appState' &&
        tracePath[1] == 'enabledFeatures' &&
        _symbol.hasMatch(value);
  }

  /// Shallow qualification precedes bounded legacy parsing; no nested walk.
  static DiagnosticScope legacyScope(Map<dynamic, dynamic> row) =>
      row['id'] is String &&
          row['errorType'] is String &&
          row['timestamp'] is String &&
          row['deviceInfo'] is Map &&
          row['appState'] is Map
      ? DiagnosticScope.trace
      : DiagnosticScope.unknown;
}
