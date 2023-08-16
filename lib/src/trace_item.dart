import 'package:meta/meta.dart';

@immutable
final class TraceItem<T> {
  final DateTime dateTime;
  final String message;
  final T? data;

  TraceItem({required this.message, this.data}) : dateTime = DateTime.now();
}
