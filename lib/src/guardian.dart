import 'handlers.dart';
import 'log.dart';

typedef GuardHandler<T> = T Function();

abstract class Guardian<T, E extends Error> {
  /// Handler for logging unexpected errors
  void onLog(GuardianLog log);

  /// Unexpected error, must be extend E
  E unexpectedError(Object error);

  final Map<Type, IHandler> _handlers = {};
  final LogExtra _extra = {};

  void extra(Map<String, dynamic> value) {
    _extra.clear();
    _extra.addAll(value);
  }

  Future<T> guard(
    GuardHandler<Future<T>> handler, {
    Duration? timeLimit,
  }) async {
    try {
      if (timeLimit != null) {
        return await handler().timeout(timeLimit);
      }

      return await handler();
    } catch (error, stackTrace) {
      return _onCatchError(error, stackTrace);
    }
  }

  T guardSync(GuardHandler<T> handler) {
    try {
      return handler();
    } catch (error, stackTrace) {
      return _onCatchError(error, stackTrace);
    }
  }

  /// Мапим ошибку
  void map<I>(MapHandler<E> onMap) {
    _checkHandler<I>();
    final key = _typeOf<I>();
    final mapper = Mapper<I, E>(onMap: onMap);
    _handlers.putIfAbsent(key, () => mapper);
  }

  /// Выполняем колбек и возвращаем то что он отдаст
  void handle<I extends Object>(HandleCallback<T> onHandle) {
    _checkHandler<I>();
    final key = _typeOf<I>();
    final handler = Handler<T>(onHandle: onHandle);
    _handlers.putIfAbsent(key, () => handler);
  }

  void _checkHandler<I>() {
    final key = _typeOf<I>();

    /// Если по такому типу уже есть маппер кидаем ошибку
    if (_handlers.containsKey(key)) {
      final message = 'Duplicate handler for type $I';
      // _onError(message: message, error: error, stackTrace: stackTrace)
      throw Exception(message);
    }
  }

  T _onCatchError(Object error, StackTrace stackTrace) {
    final key = error.runtimeType;

    if (_handlers.isEmpty) {
      const message = 'Missing handlers';
      _onError(message: message, error: error, stackTrace: stackTrace);
    } else {
      final handler = _handlers[key];

      if (handler is Mapper) {
        Object? newError;

        try {
          newError = handler.onMap(error);
        } on Object {
          final message = 'Error in handler for $key';
          _onError(message: message, error: error, stackTrace: stackTrace);
        } finally {
          if (newError != null) {
            throw Error.throwWithStackTrace(newError, stackTrace);
          }
        }
      } else if (handler is Handler) {
        try {
          return handler.onHandle(error);
        } on Object {
          final message = 'Error in handler for $key';
          _onError(message: message, error: error, stackTrace: stackTrace);
        }
      }

      const message = 'UnexpectedError';
      _onError(message: message, error: error, stackTrace: stackTrace);
    }
  }

  Never _onError({
    required String message,
    required Object error,
    required StackTrace stackTrace,
  }) {
    onLog(GuardianLog(message: message, stackTrace: stackTrace, extra: _extra));
    throw Error.throwWithStackTrace(unexpectedError(error), stackTrace);
  }

  /// Get RuntimeType from Generic
  Type _typeOf<I>() => I;
}
