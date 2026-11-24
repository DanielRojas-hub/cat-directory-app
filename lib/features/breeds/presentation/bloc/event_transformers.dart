import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';

/// Debounces rapid incoming events (e.g. search input) before handling them.
EventTransformer<E> debounceTransformer<E>(Duration duration) {
  return (events, mapper) => events.debounce(duration).switchMap(mapper);
}

/// Drops incoming events while a previous handler of the same event is running
/// (used for infinite scroll pagination and pull-to-refresh concurrency control).
EventTransformer<E> droppableTransformer<E>() => droppable<E>();
