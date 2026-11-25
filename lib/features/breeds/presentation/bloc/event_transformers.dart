import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';

/// Debounces rapid incoming events (e.g. search input) before handling them.
/// When [shouldDebounce] returns `false`, pending debounce timers are cancelled
/// and the event is forwarded immediately.
EventTransformer<E> debounceTransformer<E>(
  Duration duration, {
  bool Function(E event)? shouldDebounce,
}) {
  if (shouldDebounce == null) {
    return (events, mapper) => events.debounce(duration).switchMap(mapper);
  }
  return (events, mapper) {
    late final StreamController<E> controller;
    Timer? timer;
    StreamSubscription<E>? subscription;

    controller = StreamController<E>(
      sync: true,
      onListen: () {
        subscription = events.listen(
          (event) {
            timer?.cancel();
            if (shouldDebounce(event)) {
              timer = Timer(duration, () {
                if (!controller.isClosed) {
                  controller.add(event);
                }
              });
            } else {
              timer = null;
              if (!controller.isClosed) {
                controller.add(event);
              }
            }
          },
          onError: controller.addError,
          onDone: () {
            timer?.cancel();
            unawaited(controller.close());
          },
        );
      },
      onCancel: () {
        timer?.cancel();
        timer = null;
        return subscription?.cancel();
      },
    );

    return controller.stream.switchMap(mapper);
  };
}

/// Drops incoming events while a previous handler of the same event is running
/// (used for infinite scroll pagination and pull-to-refresh concurrency control).
EventTransformer<E> droppableTransformer<E>() => droppable<E>();
