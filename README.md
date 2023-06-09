# Guardian

Useful for ease of error management and recording unexpected errors.

## Features

- Convert from source to base error
- Return value for matched source errors
- Logging unexpected errors with extra fields

## Getting started

Create client (extends Guardian class), implements methods.

```dart

class BaseError extends Error {}

class UnexpectedError extends BaseError {}
class DivideError extends BaseError {}

class Groolt<T> extends Guardian<T, BaseError> {
  @override
  BaseError unexpectedError(Object error) {
    return UnexpectedError();
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
  final guardian = Groolt<int>()
    ..extra({'a': a, 'b': b})
    ..map<IntegerDivisionByZeroException>((err) => DivideError());

  return guardian.guardSync(() => a ~/ b);
}
```
