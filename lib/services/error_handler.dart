import 'logger_service.dart';

class ErrorHandler {
  ErrorHandler({LoggerService? logger}) : _logger = logger ?? LoggerService();

  final LoggerService _logger;

  String getUserMessage(
    Object error, {
    String fallbackMessage = 'Đã xảy ra lỗi. Vui lòng thử lại.',
  }) {
    final message = error.toString().toLowerCase();
    if (message.contains('network') || message.contains('socketexception')) {
      return 'Lỗi mạng. Vui lòng kiểm tra kết nối.';
    }
    if (message.contains('permission')) {
      return 'Bạn không có quyền thực hiện thao tác này.';
    }
    if (message.contains('timeout')) {
      return 'Kết nối bị quá thời gian. Vui lòng thử lại.';
    }
    return fallbackMessage;
  }

  void handleError(
    Object error,
    StackTrace stackTrace, {
    String? context,
    String? fallbackMessage,
    void Function(String message)? onMessage,
  }) {
    final message = getUserMessage(
      error,
      fallbackMessage: fallbackMessage ?? 'Đã xảy ra lỗi. Vui lòng thử lại.',
    );
    final logContext = context ?? 'Unhandled error';
    _logger.error(logContext, error, stackTrace);
    if (onMessage != null) {
      onMessage(message);
    }
  }

  void logError(Object error, StackTrace stackTrace, {String? context}) {
    _logger.error(context ?? 'Unhandled error', error, stackTrace);
  }
}
