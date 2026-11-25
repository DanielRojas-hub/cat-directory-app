import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/connectivity_monitor.dart';
import '../../domain/entities/breed.dart';
import '../../domain/repositories/breeds_repository.dart';
import 'breeds_event.dart';
import 'breeds_state.dart';
import 'event_transformers.dart';

/// Reactive BLoC managing the cat breeds directory with:
/// - Offline-first Stale-While-Revalidate (SWR) startup respecting cache TTL
/// - Real [CancelToken] cancellation and generation-based (`_requestEpoch`) protection
/// - `droppable()` concurrency control on startup, pagination and resume
/// - `debounce()` local in-memory search
/// - Reactive connectivity auto-recovery and foreground revalidation
final class BreedsBloc extends Bloc<BreedsEvent, BreedsState> {
  BreedsBloc({
    required this._repository,
    required this._connectivityMonitor,
    Duration searchDebounceDuration = const Duration(milliseconds: 300),
    this._foregroundRevalidateThreshold = const Duration(minutes: 5),
    DateTime Function()? clock,
  })  : _clock = clock ?? DateTime.now,
        super(const BreedsState()) {
    on<BreedsStarted>(_onStarted, transformer: droppableTransformer());
    on<BreedsRefreshed>(_onRefreshed);
    on<BreedsNextPageRequested>(
      _onNextPageRequested,
      transformer: droppableTransformer(),
    );
    on<BreedsSearchQueryChanged>(
      _onSearchQueryChanged,
      transformer: debounceTransformer(
        searchDebounceDuration,
        shouldDebounce: (event) => !event.immediate,
      ),
    );
    on<BreedsConnectivityChanged>(_onConnectivityChanged);
    on<BreedsAppResumed>(_onAppResumed, transformer: droppableTransformer());
    on<BreedsNoticeCleared>(_onNoticeCleared);

    _connectivitySubscription = _connectivityMonitor.onStatusChanged.listen(
      (isOnline) => add(BreedsConnectivityChanged(isOnline: isOnline)),
      onError: (_, _) {},
    );
  }

  final BreedsRepository _repository;
  final ConnectivityMonitor _connectivityMonitor;
  final Duration _foregroundRevalidateThreshold;
  final DateTime Function() _clock;
  StreamSubscription<bool>? _connectivitySubscription;
  int _noticeCounter = 0;
  int _requestEpoch = 0;
  bool _isRefreshing = false;
  bool _lastStartFailureRetryable = true;
  bool _lastPaginationFailureRetryable = true;
  List<Breed>? _firstPageItems;
  CancelToken? _firstPageCancelToken;
  CancelToken? _paginationCancelToken;
  final Set<Completer<void>> _queuedRefreshCompleters = <Completer<void>>{};
  final Set<Completer<void>> _activeRefreshCompleters = <Completer<void>>{};

  @override
  void onEvent(BreedsEvent event) {
    super.onEvent(event);
    if (event is BreedsRefreshed && event.completer != null) {
      _queuedRefreshCompleters.add(event.completer!);
    }
  }

  void _completeCompleters(Set<Completer<void>> completers) {
    for (final completer in List<Completer<void>>.of(completers)) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
    completers.clear();
  }

  void _cancelToken(CancelToken? token, String reason) {
    if (token != null && !token.isCancelled) {
      token.cancel(reason);
    }
  }

  CancelToken _replaceFirstPageCancelToken(String reason) {
    _cancelToken(_firstPageCancelToken, reason);
    final nextToken = CancelToken();
    _firstPageCancelToken = nextToken;
    return nextToken;
  }

  Future<T> _awaitCancellable<T>(
    Future<T> future,
    CancelToken cancelToken,
  ) {
    if (cancelToken.isCancelled) {
      return Future<T>.error(
        AppFailure.fromDioException(
          DioException.requestCancelled(
            requestOptions: RequestOptions(path: '/breeds'),
            reason: cancelToken.cancelError?.error,
          ),
        ),
      );
    }

    final completer = Completer<T>();
    future.then(
      (value) {
        if (!completer.isCompleted) {
          completer.complete(value);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
    );
    unawaited(
      cancelToken.whenCancel.then((cancelError) {
        if (!completer.isCompleted) {
          completer.completeError(AppFailure.fromDioException(cancelError));
        }
      }),
    );
    return completer.future;
  }

  BreedsNotice _buildNotice(String message, BreedsNoticeKind kind) {
    return BreedsNotice(
      message: message,
      kind: kind,
      id: ++_noticeCounter,
    );
  }

  Future<void> _onStarted(
    BreedsStarted event,
    Emitter<BreedsState> emit,
  ) async {
    final requestEpoch = ++_requestEpoch;

    try {
      // Read local cache synchronously BEFORE awaiting connectivity to eliminate
      // any skeleton frame flash on cold start when cached breeds exist.
      final cached = _repository.getCachedFirstPage();

      if (cached != null && cached.page.items.isNotEmpty) {
        _firstPageItems = cached.page.items;
        _lastStartFailureRetryable = true;

        final optimisticOnline = state.isOnline;
        final optimisticShouldRevalidate =
            optimisticOnline && cached.isExpired;

        // Offline-first SWR: render cached page 1 instantaneously.
        // When online with a fresh cache (< TTL), avoid redundant fetches and
        // clear the stale-cache banner.
        emit(
          state.copyWith(
            status: BreedsStatus.loaded,
            breeds: cached.page.items,
            currentPage: cached.page.currentPage,
            lastPage: cached.page.lastPage,
            total: cached.page.total,
            isFromCache: !optimisticOnline || cached.isExpired,
            isRevalidating: optimisticShouldRevalidate,
            isOnline: optimisticOnline,
            lastSyncedAt: cached.cachedAt,
            errorMessage: null,
            paginationErrorMessage: null,
          ),
        );

        final isOnline = await _connectivityMonitor.hasConnection;
        if (requestEpoch != _requestEpoch) {
          return;
        }

        final shouldRevalidate = isOnline && cached.isExpired;
        final targetIsFromCache = !isOnline || cached.isExpired;
        if (state.isOnline != isOnline ||
            state.isFromCache != targetIsFromCache ||
            state.isRevalidating != shouldRevalidate) {
          emit(
            state.copyWith(
              isOnline: isOnline,
              isFromCache: targetIsFromCache,
              isRevalidating: shouldRevalidate,
            ),
          );
        }

        if (!shouldRevalidate) {
          return;
        }

        // Revalidate expired page 1 in background with SWR.
        await _revalidateFirstPage(
          emit,
          requestEpoch: requestEpoch,
          showFailureNotice: true,
        );
        return;
      }

      final isOnline = await _connectivityMonitor.hasConnection;
      if (requestEpoch != _requestEpoch) {
        return;
      }

      if (!isOnline) {
        const offlineFailure = NetworkFailure();
        _lastStartFailureRetryable = offlineFailure.isRetryable;
        emit(
          state.copyWith(
            status: BreedsStatus.failure,
            isOnline: false,
            isRevalidating: false,
            isLoadingMore: false,
            errorMessage: offlineFailure.message,
            paginationErrorMessage: null,
          ),
        );
        return;
      }

      // No local cache available: show loading skeleton and fetch page 1.
      emit(
        state.copyWith(
          status: BreedsStatus.loading,
          isOnline: true,
          isRevalidating: false,
          isLoadingMore: false,
          errorMessage: null,
          paginationErrorMessage: null,
        ),
      );

      final cancelToken = _replaceFirstPageCancelToken(
        'Superseded by new initial load',
      );
      try {
        final page = await _awaitCancellable(
          _repository.fetchBreedsPage(page: 1, cancelToken: cancelToken),
          cancelToken,
        );
        if (requestEpoch != _requestEpoch || cancelToken.isCancelled) {
          return;
        }

        _firstPageItems = page.items;
        _lastStartFailureRetryable = true;
        _lastPaginationFailureRetryable = true;

        emit(
          state.copyWith(
            status: BreedsStatus.loaded,
            breeds: page.items,
            currentPage: page.currentPage,
            lastPage: page.lastPage,
            total: page.total,
            isFromCache: false,
            isRevalidating: false,
            isLoadingMore: false,
            isOnline: true,
            lastSyncedAt: _clock().toUtc(),
            errorMessage: null,
            paginationErrorMessage: null,
          ),
        );
      } finally {
        if (identical(_firstPageCancelToken, cancelToken)) {
          _firstPageCancelToken = null;
        }
      }
    } on AppFailure catch (failure) {
      if (requestEpoch != _requestEpoch || failure.isCancellation) {
        return;
      }
      _lastStartFailureRetryable = failure.isRetryable;
      _emitStartFailure(emit, failure.message);
    } on Object {
      if (requestEpoch != _requestEpoch) {
        return;
      }
      const fallback = UnknownFailure();
      _lastStartFailureRetryable = fallback.isRetryable;
      _emitStartFailure(emit, fallback.message);
    }
  }

  void _emitStartFailure(Emitter<BreedsState> emit, String message) {
    if (state.breeds.isNotEmpty) {
      emit(
        state.copyWith(
          isRevalidating: false,
          isLoadingMore: false,
          notice: _buildNotice(
            'Mostrando datos guardados ($message)',
            BreedsNoticeKind.warning,
          ),
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: BreedsStatus.failure,
          isRevalidating: false,
          isLoadingMore: false,
          errorMessage: message,
        ),
      );
    }
  }

  Future<void> _onRefreshed(
    BreedsRefreshed event,
    Emitter<BreedsState> emit,
  ) async {
    final completer = event.completer;
    if (completer != null) {
      _queuedRefreshCompleters.remove(completer);
      _activeRefreshCompleters.add(completer);
    }

    if (_isRefreshing) {
      // Share completion with the active refresh so RefreshIndicator stays
      // open until the in-flight request finishes.
      return;
    }

    _isRefreshing = true;
    int? requestEpoch;
    CancelToken? cancelToken;

    try {
      final isOnline = await _connectivityMonitor.hasConnection;

      if (!isOnline) {
        final offlineMessage = state.breeds.isNotEmpty
            ? 'Sin conexión a internet. Mostrando los datos guardados.'
            : const NetworkFailure().message;
        emit(
          state.copyWith(
            isOnline: false,
            isRevalidating: false,
            notice: _buildNotice(
              offlineMessage,
              BreedsNoticeKind.warning,
            ),
          ),
        );
        return;
      }

      // Cancel any in-flight pagination or stale page-1 request so droppable()
      // pagination handlers unblock immediately after Pull-to-Refresh.
      _cancelToken(_paginationCancelToken, 'Cancelled by Pull-to-Refresh');
      _paginationCancelToken = null;
      cancelToken = _replaceFirstPageCancelToken('Cancelled by Pull-to-Refresh');

      // Preserve offline-first local backup until remote page 1 succeeds;
      // BreedsRepository.fetchBreedsPage(page: 1) atomically overwrites cache.
      requestEpoch = ++_requestEpoch;

      emit(
        state.copyWith(
          isOnline: true,
          isRevalidating: true,
          isLoadingMore: false,
          paginationErrorMessage: null,
        ),
      );

      final page = await _awaitCancellable(
        _repository.fetchBreedsPage(page: 1, cancelToken: cancelToken),
        cancelToken,
      );
      if (requestEpoch != _requestEpoch || cancelToken.isCancelled) {
        return;
      }

      _firstPageItems = page.items;
      _lastStartFailureRetryable = true;
      _lastPaginationFailureRetryable = true;

      emit(
        state.copyWith(
          status: BreedsStatus.loaded,
          breeds: page.items,
          currentPage: page.currentPage,
          lastPage: page.lastPage,
          total: page.total,
          isFromCache: false,
          isRevalidating: false,
          isLoadingMore: false,
          isOnline: true,
          lastSyncedAt: _clock().toUtc(),
          errorMessage: null,
          paginationErrorMessage: null,
        ),
      );
    } on AppFailure catch (failure) {
      if ((requestEpoch != null && requestEpoch != _requestEpoch) ||
          failure.isCancellation) {
        return;
      }
      _lastStartFailureRetryable = failure.isRetryable;
      _emitRefreshFailure(emit, failure.message);
    } on Object {
      if (requestEpoch != null && requestEpoch != _requestEpoch) {
        return;
      }
      const fallback = UnknownFailure();
      _lastStartFailureRetryable = fallback.isRetryable;
      _emitRefreshFailure(emit, fallback.message);
    } finally {
      if (cancelToken != null &&
          identical(_firstPageCancelToken, cancelToken)) {
        _firstPageCancelToken = null;
      }
      _isRefreshing = false;
      _completeCompleters(_activeRefreshCompleters);
    }
  }

  void _emitRefreshFailure(Emitter<BreedsState> emit, String message) {
    if (state.breeds.isNotEmpty) {
      emit(
        state.copyWith(
          isRevalidating: false,
          notice: _buildNotice(
            'No se pudo actualizar: $message',
            BreedsNoticeKind.error,
          ),
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: BreedsStatus.failure,
          isRevalidating: false,
          errorMessage: message,
        ),
      );
    }
  }

  Future<void> _onNextPageRequested(
    BreedsNextPageRequested event,
    Emitter<BreedsState> emit,
  ) async {
    if (state.status != BreedsStatus.loaded ||
        !state.hasMore ||
        state.isLoadingMore ||
        state.breeds.isEmpty ||
        _isRefreshing) {
      return;
    }

    final requestEpoch = _requestEpoch;
    final nextPage = state.currentPage + 1;
    final cancelToken = CancelToken();
    _paginationCancelToken = cancelToken;

    emit(
      state.copyWith(
        isLoadingMore: true,
        paginationErrorMessage: null,
      ),
    );

    try {
      final page = await _awaitCancellable(
        _repository.fetchBreedsPage(
          page: nextPage,
          cancelToken: cancelToken,
        ),
        cancelToken,
      );
      if (cancelToken.isCancelled ||
          requestEpoch != _requestEpoch ||
          _isRefreshing) {
        return;
      }

      _lastPaginationFailureRetryable = true;
      final merged = _mergeUniqueBreeds(state.breeds, page.items);

      emit(
        state.copyWith(
          breeds: merged,
          currentPage: page.currentPage,
          lastPage: page.lastPage,
          total: page.total,
          isLoadingMore: false,
          isFromCache: false,
          isOnline: true,
          paginationErrorMessage: null,
        ),
      );
    } on AppFailure catch (failure) {
      if (cancelToken.isCancelled ||
          failure.isCancellation ||
          requestEpoch != _requestEpoch ||
          _isRefreshing) {
        return;
      }
      _lastPaginationFailureRetryable = failure.isRetryable;
      // Preserve all already-loaded breeds when an intermediate page fails.
      emit(
        state.copyWith(
          isLoadingMore: false,
          paginationErrorMessage: failure.message,
          notice: _buildNotice(
            'Error al cargar página $nextPage: ${failure.message}',
            BreedsNoticeKind.error,
          ),
        ),
      );
    } on Object {
      if (cancelToken.isCancelled ||
          requestEpoch != _requestEpoch ||
          _isRefreshing) {
        return;
      }
      const fallback = UnknownFailure();
      _lastPaginationFailureRetryable = fallback.isRetryable;
      emit(
        state.copyWith(
          isLoadingMore: false,
          paginationErrorMessage: fallback.message,
          notice: _buildNotice(
            'Error al cargar página $nextPage: ${fallback.message}',
            BreedsNoticeKind.error,
          ),
        ),
      );
    } finally {
      if (identical(_paginationCancelToken, cancelToken)) {
        _paginationCancelToken = null;
      }
    }
  }

  void _onSearchQueryChanged(
    BreedsSearchQueryChanged event,
    Emitter<BreedsState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  Future<void> _onConnectivityChanged(
    BreedsConnectivityChanged event,
    Emitter<BreedsState> emit,
  ) async {
    try {
      if (state.isOnline == event.isOnline) {
        return;
      }

      if (!event.isOnline) {
        final BreedsNotice? offlineNotice;
        if (state.breeds.isNotEmpty) {
          offlineNotice = _buildNotice(
            'Conexión perdida. Puedes seguir explorando los datos cargados.',
            BreedsNoticeKind.warning,
          );
        } else if (state.status == BreedsStatus.initial) {
          // Cold start offline with no loaded data and no prior connection loss.
          offlineNotice = null;
        } else {
          offlineNotice = _buildNotice(
            const NetworkFailure().message,
            BreedsNoticeKind.warning,
          );
        }

        emit(
          state.copyWith(
            isOnline: false,
            notice: offlineNotice,
          ),
        );
        return;
      }

      final shouldReloadFromStart =
          (state.status == BreedsStatus.failure &&
              _lastStartFailureRetryable) ||
          (state.status != BreedsStatus.failure && state.breeds.isEmpty);

      final shouldRevalidateCache =
          !shouldReloadFromStart &&
          state.status == BreedsStatus.loaded &&
          state.breeds.isNotEmpty &&
          state.isFromCache &&
          !state.isRevalidating &&
          !_isRefreshing;

      final shouldRetryPagination =
          !shouldReloadFromStart &&
          !shouldRevalidateCache &&
          state.paginationErrorMessage != null &&
          state.hasMore &&
          _lastPaginationFailureRetryable;

      final willSync =
          shouldReloadFromStart ||
          shouldRevalidateCache ||
          shouldRetryPagination;

      // Recovered connectivity: auto-recover stale cache or retryable failed loads.
      emit(
        state.copyWith(
          isOnline: true,
          isRevalidating: shouldRevalidateCache ? true : state.isRevalidating,
          notice: _buildNotice(
            willSync
                ? 'Conexión restaurada. Sincronizando directorio...'
                : 'Conexión restaurada.',
            BreedsNoticeKind.info,
          ),
        ),
      );

      if (shouldReloadFromStart) {
        add(const BreedsStarted());
      } else if (shouldRevalidateCache) {
        await _revalidateFirstPage(
          emit,
          requestEpoch: _requestEpoch,
          showFailureNotice: false,
        );
      } else if (shouldRetryPagination) {
        add(const BreedsNextPageRequested());
      }
    } on Object {
      if (!emit.isDone) {
        emit(state.copyWith(isRevalidating: false));
      }
    }
  }

  Future<void> _onAppResumed(
    BreedsAppResumed event,
    Emitter<BreedsState> emit,
  ) async {
    if (state.status != BreedsStatus.loaded ||
        _isRefreshing ||
        state.isRevalidating) {
      return;
    }

    final requestEpoch = _requestEpoch;

    try {
      final isOnline = await _connectivityMonitor.hasConnection;
      if (!isOnline ||
          requestEpoch != _requestEpoch ||
          _isRefreshing ||
          state.isRevalidating) {
        return;
      }

      final cached = _repository.getCachedFirstPage();
      final shouldRevalidate =
          event.backgroundDuration >= _foregroundRevalidateThreshold ||
          (cached?.isExpired ?? true);

      if (!shouldRevalidate) {
        return;
      }

      emit(state.copyWith(isRevalidating: true, isOnline: true));

      await _revalidateFirstPage(
        emit,
        requestEpoch: requestEpoch,
        showFailureNotice: false,
      );
    } on Object {
      if (requestEpoch == _requestEpoch && !_isRefreshing && !emit.isDone) {
        emit(state.copyWith(isRevalidating: false));
      }
    }
  }

  void _onNoticeCleared(
    BreedsNoticeCleared event,
    Emitter<BreedsState> emit,
  ) {
    emit(state.copyWith(notice: null));
  }

  Future<void> _revalidateFirstPage(
    Emitter<BreedsState> emit, {
    required int requestEpoch,
    required bool showFailureNotice,
  }) async {
    final cancelToken = _replaceFirstPageCancelToken(
      'Superseded by new page-1 revalidation',
    );
    try {
      final freshPage = await _awaitCancellable(
        _repository.fetchBreedsPage(page: 1, cancelToken: cancelToken),
        cancelToken,
      );
      if (cancelToken.isCancelled ||
          requestEpoch != _requestEpoch ||
          _isRefreshing) {
        return;
      }

      if (state.currentPage > 1) {
        if (freshPage.items.isEmpty) {
          emit(
            state.copyWith(
              isRevalidating: false,
              isOnline: true,
              lastSyncedAt: _clock().toUtc(),
            ),
          );
          return;
        }

        // Update page-1 slice in place while preserving items loaded from pages > 1.
        final updatedBreeds = _mergeRevalidatedFirstPage(
          freshFirstPage: freshPage.items,
          currentBreeds: state.breeds,
        );
        _firstPageItems = freshPage.items;

        final nextLastPage = freshPage.lastPage;
        final nextCurrentPage = nextLastPage > 0
            ? math.min(state.currentPage, nextLastPage)
            : state.currentPage;

        emit(
          state.copyWith(
            breeds: updatedBreeds,
            currentPage: nextCurrentPage,
            lastPage: nextLastPage,
            total: freshPage.total,
            isRevalidating: false,
            isFromCache: false,
            isOnline: true,
            lastSyncedAt: _clock().toUtc(),
          ),
        );
        return;
      }

      _firstPageItems = freshPage.items;

      emit(
        state.copyWith(
          status: BreedsStatus.loaded,
          breeds: freshPage.items,
          currentPage: freshPage.currentPage,
          lastPage: freshPage.lastPage,
          total: freshPage.total,
          isFromCache: false,
          isRevalidating: false,
          isOnline: true,
          lastSyncedAt: _clock().toUtc(),
          errorMessage: null,
          paginationErrorMessage: null,
        ),
      );
    } on AppFailure catch (failure) {
      if (cancelToken.isCancelled ||
          failure.isCancellation ||
          requestEpoch != _requestEpoch ||
          _isRefreshing) {
        return;
      }
      emit(
        state.copyWith(
          isRevalidating: false,
          notice: showFailureNotice && state.breeds.isNotEmpty
              ? _buildNotice(
                  'Mostrando datos guardados (${failure.message})',
                  BreedsNoticeKind.warning,
                )
              : null,
        ),
      );
    } on Object {
      if (cancelToken.isCancelled ||
          requestEpoch != _requestEpoch ||
          _isRefreshing) {
        return;
      }
      const fallback = UnknownFailure();
      emit(
        state.copyWith(
          isRevalidating: false,
          notice: showFailureNotice && state.breeds.isNotEmpty
              ? _buildNotice(
                  'Mostrando datos guardados (${fallback.message})',
                  BreedsNoticeKind.warning,
                )
              : null,
        ),
      );
    } finally {
      if (identical(_firstPageCancelToken, cancelToken)) {
        _firstPageCancelToken = null;
      }
    }
  }

  List<Breed> _mergeRevalidatedFirstPage({
    required List<Breed> freshFirstPage,
    required List<Breed> currentBreeds,
  }) {
    final previousFirstPage = _firstPageItems;
    final Iterable<Breed> tailBreeds;
    if (previousFirstPage != null && previousFirstPage.isNotEmpty) {
      final staleFirstPageNames =
          previousFirstPage.map((b) => b.breed.toLowerCase()).toSet();
      tailBreeds = currentBreeds.where(
        (b) => !staleFirstPageNames.contains(b.breed.toLowerCase()),
      );
    } else {
      tailBreeds = currentBreeds;
    }
    return _mergeUniqueBreeds(freshFirstPage, tailBreeds);
  }

  List<Breed> _mergeUniqueBreeds(
    List<Breed> existing,
    Iterable<Breed> incoming,
  ) {
    final seen = existing.map((b) => b.breed.toLowerCase()).toSet();
    final result = List<Breed>.of(existing);
    for (final breed in incoming) {
      if (seen.add(breed.breed.toLowerCase())) {
        result.add(breed);
      }
    }
    return List<Breed>.unmodifiable(result);
  }

  @override
  Future<void> close() async {
    _cancelToken(_paginationCancelToken, 'BreedsBloc closed');
    _paginationCancelToken = null;
    _cancelToken(_firstPageCancelToken, 'BreedsBloc closed');
    _firstPageCancelToken = null;
    await _connectivitySubscription?.cancel();
    _completeCompleters(_activeRefreshCompleters);
    _completeCompleters(_queuedRefreshCompleters);
    return super.close();
  }
}
