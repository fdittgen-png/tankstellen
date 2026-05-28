// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/error_trace.dart';
import '../../../core/logging/error_logger.dart';

class NetworkStateCollector {
  static Future<NetworkSnapshot> collect() async {
    try {
      final results = await Connectivity().checkConnectivity();
      final isOnline =
          results.isNotEmpty && !results.contains(ConnectivityResult.none);
      String type = 'none';
      if (results.contains(ConnectivityResult.wifi)) {
        type = 'wifi';
      } else if (results.contains(ConnectivityResult.mobile)) {
        type = 'mobile';
      } else if (results.contains(ConnectivityResult.ethernet)) {
        type = 'ethernet';
      }
      return NetworkSnapshot(isOnline: isOnline, connectivityType: type);
    } on Exception catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'NetworkStateCollector: connectivity check failed'}));
      return const NetworkSnapshot(isOnline: false, connectivityType: 'unknown');
    }
  }
}
