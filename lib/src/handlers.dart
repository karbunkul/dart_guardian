typedef MapCallback<I, T> = T Function(I error);
typedef HandleCallback<T, I> = T Function(I error);

abstract class IHandler<T> {
  bool hasApply(Object value) => value is T;

  @override
  String toString() {
    final type = runtimeType.toString();
    final pattern = RegExp(r'(?<=\<)(.+?)(?=\>)');
    final match = pattern.allMatches(type).first;

    return type.substring(match.start, match.end).replaceFirst(', ', ' -> ');
  }
}

class Mapper<I extends Object, O> extends IHandler<I> {
  final MapCallback<I, O> onMap;

  Mapper({required this.onMap});

  O castMap(Object error) {
    return onMap(error as I);
  }
}

class Handler<O, I> extends IHandler<I> {
  final HandleCallback<O, I> onHandle;

  Handler({required this.onHandle});

  O castHandle(Object error) {
    return onHandle(error as I);
  }

  @override
  String toString() {
    final type = runtimeType.toString();
    final pattern = RegExp(r'(?<=\<)(.+?)(?=\>)');
    final match = pattern.allMatches(type).first;

    return type.substring(match.start, match.end).split(', ').last;
  }
}
