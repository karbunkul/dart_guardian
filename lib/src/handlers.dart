typedef MapHandler<T> = T Function(Object error);
typedef HandleCallback<T> = T Function(Object error);

abstract class IHandler {}

class Mapper<I, O> extends IHandler {
  final MapHandler<O> onMap;

  Mapper({required this.onMap});
}

class Handler<O> extends IHandler {
  final HandleCallback<O> onHandle;

  Handler({required this.onHandle});
}
