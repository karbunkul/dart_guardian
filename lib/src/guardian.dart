import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'exceptions.dart';
import 'handlers.dart';
import 'log.dart';

typedef GuardHandler<T> = T Function();
typedef UnexpectedCallback<E> = E Function(Object error);

abstract class BaseGuardian<T, E extends Error> {
  final Map<Type, IHandler> _handlers = {};
  final LogExtra _extra = {};
  UnexpectedCallback<E>? _unexpectedCallback;

  /// Handler for logging unexpected errors
  @protected
  void onLog(GuardianLog log);

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
      } on Object catch (err, stack) {
        final key = error.runtimeType;
        final message = 'Error in handler for $key';
        _onError(message: message, error: err, stackTrace: stack);
      } finally {
        if (newError != null) {
          throw Error.throwWithStackTrace(newError, stackTrace);
        }
      }
    }

    if (handler is Handler) {
      try {
        return handler.castHandle(error);
      } on Object catch (err, stack) {
        final key = error.runtimeType;
        final message = 'Error in handler for $key';
        _onError(message: message, error: err, stackTrace: stack);
      }
    }

    if (error is E) {
      throw Error.throwWithStackTrace(error, stackTrace);
    }

    const message = 'UnexpectedError';
    _onError(message: message, error: error, stackTrace: stackTrace);
  }

  /// Log unexpected error
  Never _onError({
    required String message,
    required Object error,
    required StackTrace stackTrace,
  }) {
    onLog(
      GuardianLog(
        message: message,
        error: error,
        stackTrace: stackTrace,
        extra: _extra,
      ),
    );

    final callback = _unexpectedCallback ?? unexpectedError;
    throw Error.throwWithStackTrace(callback(error), stackTrace);
  }

  /// Get Type from Generic
  Type _typeOf<I>() => I;
}
