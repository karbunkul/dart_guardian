import 'package:meta/meta.dart';

import 'error_report.dart';
import 'exceptions.dart';

typedef OnLogCallback = void Function(ErrorReport);

class GuardianObserver {
  static final _singleton = GuardianObserver._();
  static OnLogCallback? _onLog;

  factory GuardianObserver() => _singleton;

  GuardianObserver._();

  static init(OnLogCallback onLog) {
    if (_onLog != null) {
      throw GuardianObserverAlreadyInitializedException();
    }
    _onLog = onLog;
  }

  static OnLogCallback get onLog {
    if (_onLog == null) {
      throw GuardianObserverNotInitializedException();
    }
    return _onLog!;
  }

  @visibleForTesting
  static reset() {
    _onLog = null;
  }

  @visibleForTesting
  static stub() {
    _onLog = (_) {};
  }
}
