typedef MapCallback<I, T> = T Function(I error);
typedef HandleCallback<T> = T Function(Object error);

abstract class IHandler {}

class Mapper<I extends Object, O> extends IHandler {
  final MapCallback<I, O> onMap;

  Mapper({required this.onMap});

  O castMap(Object error) {
    return onMap(error as I);
  }
}

class Handler<O> extends IHandler {
  final HandleCallback<O> onHandle;

  Handler({required this.onHandle});
}
