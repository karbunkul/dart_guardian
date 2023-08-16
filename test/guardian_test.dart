import 'dart:async';

import 'package:guardian/guardian.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class BaseException extends Error {}

class FatalException extends BaseException {}

class LimitException extends BaseException {}

abstract class ILog {
  void onLog(GuardianLog log);
}

class LogMock extends Mock implements ILog {}

class Guardian<T> extends BaseGuardian<T, BaseException> {
  final LogMock mock;

  Guardian(this.mock);

  @override
  void onLog(GuardianLog log) => mock.onLog(log);

  @override
  BaseException unexpectedError(Object error) => FatalException();
}

class GuardianLogMock extends Mock implements GuardianLog {}

void main() {
  final logMock = LogMock();
  final extra = {'foo': 'bar'};

  setUp(() => reset(logMock));

  setUpAll(() {
    registerFallbackValue(GuardianLogMock());
  });

  group('Guardian tests', () {
    group('map', () {
      final guardian = Guardian<void>(logMock);

      test('two or more duplicates of mapper', () {
        expect(
          () {
            guardian.map<TimeoutException>((_) => LimitException());
            guardian.map<TimeoutException>((_) => LimitException());
          },
          throwsA(TypeMatcher<GuardianDuplicateException>()),
        );
      });

      test('allow only one type for register (map or handle)', () {
        expect(
          () {
            guardian.map<TimeoutException>((_) => LimitException());
            guardian.handle<TimeoutException>((_) => {});
          },
          throwsA(TypeMatcher<GuardianDuplicateException>()),
        );
      });
    });

    group('handle', () {
      final guardian = Guardian<void>(logMock);

      test('two or more duplicates of handler', () {
        expect(
          () {
            guardian.handle<TimeoutException>((_) => {});
            guardian.handle<TimeoutException>((_) => {});
          },
          throwsA(TypeMatcher<GuardianDuplicateException>()),
        );
      });

      test('allow only one type for register (map or handle)', () {
        expect(
          () {
            guardian.map<TimeoutException>((_) => LimitException());
            guardian.handle<TimeoutException>((_) => {});
          },
          throwsA(TypeMatcher<GuardianDuplicateException>()),
        );
      });
    });

    group('guard', () {
      test('map successful', () {
        final guardian = Guardian<void>(logMock);
        guardian
          ..map<Exception>((_) => LimitException())
          ..map<TimeoutException>((_) => LimitException());
        expect(
          guardian.guard((_) => throw TimeoutException('')),
          throwsA(TypeMatcher<LimitException>()),
        );

        expect(
          () => guardian.guard((_) => throw Exception()),
          throwsA(TypeMatcher<LimitException>()),
        );
      });

      test('map failed', () {
        //throw exception and log it, if failed map callback
        final guardian = Guardian<void>(logMock);
        guardian.extra(extra);
        guardian.map<ArgumentError>((error) => throw Exception());

        expect(
          guardian.guard((_) => throw ArgumentError('')),
          throwsA(TypeMatcher<FatalException>()),
        );

        final captured = verify(() => guardian.mock.onLog(captureAny()));
        expect(captured.callCount, equals(1));
        final log = captured.captured.first as GuardianLog;

        expect(log.extra.toString(), equals(extra.toString()));
        expect(log.message, equals('Error in handler for ArgumentError'));
      });

      test('handle successful', () async {
        final guardian = Guardian<int>(logMock);
        guardian.handle<TimeoutException>((error) => 10);
        expect(
          await guardian.guard((_) => throw TimeoutException('')),
          equals(10),
        );
      });

      test('handle failed', () {
        final guardian = Guardian<int>(logMock);
        guardian.extra(extra);
        guardian.handle<ArgumentError>((error) => throw ArgumentError());

        expect(
          guardian.guard((_) => throw ArgumentError('')),
          throwsA(TypeMatcher<FatalException>()),
        );

        final captured = verify(() => guardian.mock.onLog(captureAny()));
        expect(captured.callCount, equals(1));
        final log = captured.captured.first as GuardianLog;

        expect(log.extra.toString(), equals(extra.toString()));
        expect(log.message, equals('Error in handler for ArgumentError'));
      });

      test('pass if error is base exception', () {
        final guardian = Guardian<int>(logMock);
        guardian.handle<TimeoutException>((error) => 10);
        //TODO(karbunkul): Need check stackTrace
        expect(
          guardian.guard((_) => throw LimitException()),
          throwsA(TypeMatcher<LimitException>()),
        );
      });

      test('time limit', () async {
        final guardian = Guardian<int>(logMock);
        guardian.map<TimeoutException>((error) => LimitException());

        expect(
          guardian.guard(
            (_) async {
              await Future.delayed(const Duration(milliseconds: 20));
              return 1;
            },
            timeLimit: Duration.zero,
          ),
          throwsA(TypeMatcher<LimitException>()),
        );
      });
    });

    group('guardSync', () {
      test('map successful', () {
        final guardian = Guardian<void>(logMock);

        guardian
          ..map<Exception>((_) => LimitException())
          ..map<TimeoutException>((_) => LimitException());
        expect(
          () => guardian.guardSync((_) => throw TimeoutException('')),
          throwsA(TypeMatcher<LimitException>()),
        );

        expect(
          () => guardian.guardSync((_) => throw Exception()),
          throwsA(TypeMatcher<LimitException>()),
        );
      });

      test('map failed', () {
        //throw exception and log it, if failed map callback
        final guardian = Guardian<void>(logMock);
        guardian.extra(extra);
        guardian.map<ArgumentError>((error) => throw Exception());

        expect(
          () => guardian.guardSync((_) => throw ArgumentError('')),
          throwsA(TypeMatcher<FatalException>()),
        );

        final captured = verify(() => guardian.mock.onLog(captureAny()));
        expect(captured.callCount, equals(1));
        final log = captured.captured.first as GuardianLog;

        expect(log.extra.toString(), equals(extra.toString()));
        expect(log.message, equals('Error in handler for ArgumentError'));
      });

      test('handle successful', () {
        final guardian = Guardian<int>(logMock);
        guardian.handle<TimeoutException>((error) => 10);
        expect(
          guardian.guardSync((_) => throw TimeoutException('')),
          equals(10),
        );
      });

      test('handle failed', () async {
        final guardian = Guardian<int>(logMock);
        guardian.extra(extra);
        guardian.handle<ArgumentError>((error) => throw ArgumentError());

        expect(
          () => guardian.guardSync((_) => throw ArgumentError('')),
          throwsA(TypeMatcher<FatalException>()),
        );

        final captured = verify(() => guardian.mock.onLog(captureAny()));
        expect(captured.callCount, equals(1));
        final log = captured.captured.first as GuardianLog;

        expect(log.extra.toString(), equals(extra.toString()));
        expect(log.message, equals('Error in handler for ArgumentError'));
      });

      test('pass if error is base exception', () {
        final guardian = Guardian<int>(logMock);
        guardian.handle<TimeoutException>((error) => 10);

        expect(
          () => guardian.guardSync((_) => throw LimitException()),
          throwsA(TypeMatcher<LimitException>()),
        );
      });
    });
  });
}
