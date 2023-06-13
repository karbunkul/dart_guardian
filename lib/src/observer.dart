import 'package:meta/meta.dart';

import 'exceptions.dart';
import 'log.dart';

typedef OnLogCallback = void Function(GuardianLog);

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
}
