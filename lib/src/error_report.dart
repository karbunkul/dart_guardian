import 'package:guardian/src/log_item.dart';

typedef LogExtra = Map<String, dynamic>;

class ErrorReport {
  final String message;
  final Object error;
  final StackTrace stackTrace;
  final LogExtra extra;
  final List<LogItem> logs;

  ErrorReport({
    required this.message,
    required this.error,
    required this.stackTrace,
    required this.extra,
    required this.logs,
  });
}
