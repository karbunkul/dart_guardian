abstract class Logger {
  const Logger();
  void message(String message);
  void info<T>({required String message, required T data});
}
