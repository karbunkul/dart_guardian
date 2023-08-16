import 'dart:async';

import 'package:collection/collection.dart';
import 'package:guardian/src/log_item.dart';
import 'package:meta/meta.dart';

import 'error_report.dart';
import 'exceptions.dart';
import 'handlers.dart';
import 'logger.dart';

typedef GuardHandler<T> = T Function(Logger logger);
typedef UnexpectedCallback<E> = E Function(Object error);

abstract class BaseGuardian<T, E extends Error> {
  final Map<Type, IHandler> _handlers = {};
  final LogExtra _extra = {};
  late final _logger = _Logger(onTrace: onLog);
  bool _verbose = false;

  UnexpectedCallback<E>? _unexpectedCallback;

  /// Handler for logging unexpected errors
  @protected
  void onReport(ErrorReport log);

  /// Unexpected error, must be extend E
  @protected
  E unexpectedError(Object error);

  /// Log expected error with extra fields
  BaseGuardian<T, E> extra(LogExtra value) {
    _extra.clear();
    _extra.addAll(value);
    return this;
  }

  BaseGuardian<T, E> defaultError(UnexpectedCallback<E> callback) {
    _unexpectedCallback = callback;

    return this;
  }

  Future<T> guard(
    GuardHandler<Future<T>> handler, {
    Duration? timeLimit,
  }) async {
    _logger.clear();
    try {
      if (timeLimit != null) {
        return await handler(_logger).timeout(timeLimit);
      }

      return await handler(_logger);
    } catch (error, stackTrace) {
      return _onCatchError(error, stackTrace);
    }
  }

  T guardSync(GuardHandler<T> handler) {
    _logger.clear();
    try {
      return handler(_logger);
    } catch (error, stackTrace) {
      return _onCatchError(error, stackTrace);
    }
  }

  /// Setup logger name
  BaseGuardian<T, E> loggerName(String name) {
    _logger.name = name;
    return this;
  }

  /// Setup logger name
  BaseGuardian<T, E> verboseMode(bool verbose) {
    _verbose = verbose;
    return this;
  }

  /// Convert error to exception extend from E
  BaseGuardian<T, E> map<I extends Object>(MapCallback<I, E> onMap) {
    _checkDuplicates<I>();
    _handlers.putIfAbsent(_typeOf<I>(), () => Mapper<I, E>(onMap: onMap));

    return this;
  }

  /// Return value if catch error
  BaseGuardian<T, E> handle<I extends Object>(HandleCallback<T, I> onHandle) {
    _checkDuplicates<I>();
    _handlers.putIfAbsent(
        _typeOf<I>(), () => Handler<T, I>(onHandle: onHandle));

    return this;
  }

  void _checkDuplicates<I>() {
    if (_handlers.containsKey(_typeOf<I>())) {
      throw GuardianDuplicateException(I);
    }
  }

  IHandler? _findMapper(Object error) {
    final key = error.runtimeType;

    if (_handlers.containsKey(key)) {
      return _handlers[key];
    } else {
      return _handlers.values
          .firstWhereOrNull((element) => element.hasApply(error));
    }
  }

  /// Process error, map or handle
  T _onCatchError(Object error, StackTrace stackTrace) {
    final handler = _findMapper(error);

    if (handler is Mapper) {
      Object? newError;

      try {
        newError = handler.castMap(error);
        if (_verbose) {
          _logger.verbose(message: 'Map error: $handler successfully done');
        }
      } on Object catch (err, stack) {
        final key = error.runtimeType;
        final message = 'Error in handler for $key';
        if (_verbose) {
          _logger.message(message);
        }
        _onReport(message: message, error: err, stackTrace: stack);
      } finally {
        if (newError != null) {
          throw Error.throwWithStackTrace(newError, stackTrace);
        }
      }
    }

    if (handler is Handler) {
      try {
        final result = handler.castHandle(error);
        if (_verbose) {
          _logger.verbose(message: 'Handle error: $handler successfully done');
        }

        return result;
      } on Object catch (err, stack) {
        final key = error.runtimeType;
        final message = 'Error in handler for $key';
        if (_verbose) {
          _logger.verbose(message: message);
        }
        _onReport(message: message, error: err, stackTrace: stack);
      }
    }

    if (error is E) {
      throw Error.throwWithStackTrace(error, stackTrace);
    }

    const message = 'UnexpectedError';
    _onReport(message: message, error: error, stackTrace: stackTrace);
  }

  /// Log unexpected error
  Never _onReport({
    required String message,
    required Object error,
    required StackTrace stackTrace,
  }) {
    onReport(
      ErrorReport(
        message: message,
        error: error,
        stackTrace: stackTrace,
        extra: _extra,
        logs: _logger.items,
      ),
    );

    final callback = _unexpectedCallback ?? unexpectedError;
    throw Error.throwWithStackTrace(callback(error), stackTrace);
  }

  void onLog(LogItem item) {}

  /// Get Type from Generic
  Type _typeOf<I>() => I;
}

typedef OnTraceCallback = void Function(LogItem item);

class _Logger extends Logger {
  final OnTraceCallback onTrace;
  String? _name;

  final List<LogItem> _items = [];

  _Logger({required this.onTrace});

  set name(String value) => _name = value;

  @override
  void info<T>({required String message, required T data}) {
    final item = LogItem(
      message: message,
      data: data,
      logger: _name,
      sourceLine: _sourceLine(2),
    );
    _items.add(item);
    onTrace(item);
  }

  @override
  void message(String message) {
    final item = LogItem(
      message: message,
      logger: _name,
      sourceLine: _sourceLine(2),
    );

    _items.add(item);
    onTrace(item);
  }

  void verbose<T>({required String message, T? data}) {
    final item = LogItem(
      message: message,
      data: data,
      logger: _name,
    );
    onTrace(item);
  }

  void clear() => _items.clear();
  List<LogItem> get items => List.unmodifiable(_items);

  String _sourceLine(int depth) {
    return StackTrace.current
        .toString()
        .split('\n')[depth]
        .replaceAll(RegExp(r'^.[^\(]+'), '');
  }
}
