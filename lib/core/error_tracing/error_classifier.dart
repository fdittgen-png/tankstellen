import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../error/exceptions.dart';
import 'models/error_trace.dart';

class ErrorClassifier {
  static ErrorCategory classify(Object error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        return ErrorCategory.network;
      }
      return ErrorCategory.api;
    }
    if (error is ApiException) return ErrorCategory.api;
    if (error is CacheException) return ErrorCategory.cache;
    if (error is LocationException) return ErrorCategory.platform;
    if (error is NoApiKeyException) return ErrorCategory.api;
    if (error is ServiceChainExhaustedException) {
      return ErrorCategory.serviceChain;
    }
    if (error is FlutterError) return ErrorCategory.ui;
    return ErrorCategory.unknown;
  }
}
