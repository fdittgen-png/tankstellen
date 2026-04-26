import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/error_trace.dart';

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
      debugPrint('NetworkStateCollector: connectivity check failed: $e\n$st');
      return const NetworkSnapshot(isOnline: false, connectivityType: 'unknown');
    }
  }
}
