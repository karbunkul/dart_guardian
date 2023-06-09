typedef LogExtra = Map<String, dynamic>;

class GuardianLog {
  final String message;
  final Object error;
  final StackTrace stackTrace;
  final LogExtra extra;

  GuardianLog({
    required this.message,
    required this.error,
    required this.stackTrace,
    required this.extra,
  });
}
