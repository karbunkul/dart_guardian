# Guardian

Useful for ease of error management and recording unexpected errors.

## Features

- Convert from source to base exception
- Return value for matched source errors
- Logging unexpected errors with extra fields

## Getting started

Create client (extends Guardian class), implements methods.

```dart

class BaseException extends Error {}

class UnexpectedFatalException extends BaseException {}

class Groolt<T> extends Guardian<T, BaseException> {
  @override
  BaseException unexpectedError(Object error) {
    return UnexpectedFatalException();
  }

  @override
  void onLog(GuardianLog log) {
    print(log.message);
  }
}
```

## Usage

```dart

Future<void> main() async {
  try {
    final res = divide(5, 0);
    print(res);
  } catch (e) {
    print(e.runtimeType);
    print(e.stackTrace);
  }
}

int divide(int a, int b) {
  final guardian = Groolt<int>()..extra({'a': a, 'b': b});
  guardian.map<IntegerDivisionByZeroException>((err) => DivideException());

  return guardian.guardSync(() => a ~/ b);
}
```
