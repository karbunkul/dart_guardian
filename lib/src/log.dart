typedef LogExtra = Map<String, dynamic>;

class GuardianLog {
  final String message;
  final StackTrace stackTrace;
  final LogExtra extra;

  GuardianLog({
    required this.message,
    required this.stackTrace,
    required this.extra,
  });
}
