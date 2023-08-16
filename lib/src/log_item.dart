import 'package:meta/meta.dart';

@immutable
final class LogItem<T> {
  final DateTime dateTime;
  final String message;
  final String? sourceLine;
  final String? logger;
  final T? data;

  LogItem({
    required this.message,
    this.data,
    this.logger,
    this.sourceLine,
  }) : dateTime = DateTime.now();

  @override
  String toString() {
    return ('message=$message, timestamp=${dateTime.millisecondsSinceEpoch}, data=$data');
  }
}
