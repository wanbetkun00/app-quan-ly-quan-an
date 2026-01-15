import 'package:flutter/foundation.dart';

class LoggerService {
  void info(String message) {
    debugPrint('[INFO] $message');
  }

  void warning(String message, {Object? error, StackTrace? stackTrace}) {
    debugPrint('[WARN] $message');
    if (error != null) {
      debugPrint('[WARN] Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('[WARN] StackTrace: $stackTrace');
    }
  }

  void error(String message, Object error, StackTrace stackTrace) {
    debugPrint('[ERROR] $message');
    debugPrint('[ERROR] Error: $error');
    debugPrint('[ERROR] StackTrace: $stackTrace');
  }
}
