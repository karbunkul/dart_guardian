import 'dart:async';

import 'package:guardian/guardian.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

abstract class ILog {
  void onLog(ErrorReport log);
}

class LogMock extends Mock implements ILog {}

class GuardianLogMock extends Mock implements ErrorReport {}

class StackTraceMock extends Mock implements StackTrace {}

void main() {
  setUpAll(() {
    registerFallbackValue(GuardianLogMock());
    registerFallbackValue(StackTraceMock());
  });

  tearDown(() {
    GuardianObserver.reset();
  });

  group('GuardianObserver Tests', () {
    test('GuardianObserver must be singleton', () {
      final a = GuardianObserver();
      final b = GuardianObserver();
      expect(a == b, equals(true));
    });

    test('check not initialized', () {
      expect(
        () => GuardianObserver.onLog,
        throwsA(TypeMatcher<GuardianObserverNotInitializedException>()),
      );
    });

    test('already initialized', () {
      GuardianObserver.init((_) {});
      expect(
        () => GuardianObserver.init((_) {}),
        throwsA(TypeMatcher<GuardianObserverAlreadyInitializedException>()),
      );
    });

    test('on log', () {
      final mock = LogMock();

      GuardianObserver.init(mock.onLog);
      const extra = {'foo': 'bar'};
      const message = 'test message';
      final stackTrace = StackTraceMock();
      final error = TimeoutException('test');

      GuardianObserver.onLog(
        ErrorReport(
          message: message,
          error: error,
          stackTrace: stackTrace,
          extra: extra,
          logs: [],
        ),
      );

      final captured = verify(() => mock.onLog(captureAny()));
      expect(captured.callCount, equals(1));
      final log = captured.captured.first as ErrorReport;

      expect(log.extra.toString(), equals(extra.toString()));
      expect(log.message, equals(message));
      expect(log.error, equals(error));
      expect(log.stackTrace, TypeMatcher<StackTrace>());
    });

    test('stub', () {
      GuardianObserver.stub();
      expect(() => GuardianObserver.onLog, returnsNormally);
    });
  });
}
