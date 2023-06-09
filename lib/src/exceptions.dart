class GuardianException extends Error {}

class GuardianEmptyHandlersException extends Error {}

class GuardianDuplicateException extends Error {
  final Type type;

  GuardianDuplicateException(this.type);
}