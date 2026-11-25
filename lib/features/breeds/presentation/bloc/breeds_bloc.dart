import 'dart:async';

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
/// - Generation-based (`_requestEpoch`) concurrency protection across loads
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
  final Set<Completer<void>> _pendingRefreshCompleters = <Completer<void>>{};

  @override
  void onEvent(BreedsEvent event) {
    super.onEvent(event);
    if (event is BreedsRefreshed && event.completer != null) {
      _pendingRefreshCompleters.add(event.completer!);
    }
  }

  void _completeRefreshCompleter(Completer<void>? completer) {
    if (completer == null) return;
    _pendingRefreshCompleters.remove(completer);
    if (!completer.isCompleted) {
      completer.complete();
    }
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
      final isOnline = await _connectivityMonitor.hasConnection;
      if (requestEpoch != _requestEpoch) {
        return;
      }

      final cached = _repository.getCachedFirstPage();

      if (cached != null && cached.page.items.isNotEmpty) {
        final shouldRevalidate = isOnline && cached.isExpired;

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
            isFromCache: !isOnline || cached.isExpired,
            isRevalidating: shouldRevalidate,
            isOnline: isOnline,
            lastSyncedAt: cached.cachedAt,
            errorMessage: null,
            paginationErrorMessage: null,
          ),
        );

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

      // No local cache available: show loading skeleton and fetch page 1.
      emit(
        state.copyWith(
          status: BreedsStatus.loading,
          isOnline: isOnline,
          isRevalidating: false,
          isLoadingMore: false,
          errorMessage: null,
          paginationErrorMessage: null,
        ),
      );

      final page = await _repository.fetchBreedsPage(page: 1);
      if (requestEpoch != _requestEpoch) {
        return;
      }

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
      if (requestEpoch != _requestEpoch) {
        return;
      }
      _emitStartFailure(emit, failure.message);
    } on Object {
      if (requestEpoch != _requestEpoch) {
        return;
      }
      const fallback = UnknownFailure();
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
    if (_isRefreshing) {
      _completeRefreshCompleter(event.completer);
      return;
    }

    _isRefreshing = true;
    int? requestEpoch;

    try {
      final isOnline = await _connectivityMonitor.hasConnection;

      if (!isOnline) {
        emit(
          state.copyWith(
            isOnline: false,
            isRevalidating: false,
            notice: _buildNotice(
              'Sin conexión a internet. Mostrando los datos guardados.',
              BreedsNoticeKind.warning,
            ),
          ),
        );
        return;
      }

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

      final page = await _repository.fetchBreedsPage(page: 1);
      if (requestEpoch != _requestEpoch) {
        return;
      }

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
      if (requestEpoch != null && requestEpoch != _requestEpoch) {
        return;
      }
      _emitRefreshFailure(emit, failure.message);
    } on Object {
      if (requestEpoch != null && requestEpoch != _requestEpoch) {
        return;
      }
      const fallback = UnknownFailure();
      _emitRefreshFailure(emit, fallback.message);
    } finally {
      _isRefreshing = false;
      _completeRefreshCompleter(event.completer);
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
    emit(
      state.copyWith(
        isLoadingMore: true,
        paginationErrorMessage: null,
      ),
    );

    try {
      final page = await _repository.fetchBreedsPage(page: nextPage);
      if (requestEpoch != _requestEpoch || _isRefreshing) {
        return;
      }

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
      if (requestEpoch != _requestEpoch || _isRefreshing) {
        return;
      }
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
      if (requestEpoch != _requestEpoch || _isRefreshing) {
        return;
      }
      const fallback = UnknownFailure();
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
      final wasOffline = !state.isOnline;
      if (state.isOnline == event.isOnline) {
        return;
      }

      if (!event.isOnline) {
        emit(
          state.copyWith(
            isOnline: false,
            notice: _buildNotice(
              'Conexión perdida. Puedes seguir explorando los datos cargados.',
              BreedsNoticeKind.warning,
            ),
          ),
        );
        return;
      }

      final shouldRevalidateCache =
          state.status == BreedsStatus.loaded &&
          state.breeds.isNotEmpty &&
          state.isFromCache &&
          !state.isRevalidating &&
          !_isRefreshing;

      // Recovered connectivity: auto-recover stale cache or failed loads.
      emit(
        state.copyWith(
          isOnline: true,
          isRevalidating: shouldRevalidateCache ? true : state.isRevalidating,
          notice: wasOffline
              ? _buildNotice(
                  'Conexión restaurada. Sincronizando directorio...',
                  BreedsNoticeKind.info,
                )
              : null,
        ),
      );

      if (state.status == BreedsStatus.failure || state.breeds.isEmpty) {
        add(const BreedsStarted());
      } else if (shouldRevalidateCache) {
        await _revalidateFirstPage(
          emit,
          requestEpoch: _requestEpoch,
          showFailureNotice: false,
        );
      } else if (state.paginationErrorMessage != null && state.hasMore) {
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
    try {
      final freshPage = await _repository.fetchBreedsPage(page: 1);
      if (requestEpoch != _requestEpoch || _isRefreshing) {
        return;
      }

      if (state.currentPage > 1) {
        // Refresh page 1 cache without disrupting deeper scroll progress.
        emit(
          state.copyWith(
            isRevalidating: false,
            isFromCache: false,
            isOnline: true,
            lastSyncedAt: _clock().toUtc(),
          ),
        );
        return;
      }

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
      if (requestEpoch != _requestEpoch || _isRefreshing) {
        return;
      }
      emit(
        state.copyWith(
          isRevalidating: false,
          notice: showFailureNotice
              ? _buildNotice(
                  'Mostrando datos guardados (${failure.message})',
                  BreedsNoticeKind.warning,
                )
              : null,
        ),
      );
    } on Object {
      if (requestEpoch != _requestEpoch || _isRefreshing) {
        return;
      }
      const fallback = UnknownFailure();
      emit(
        state.copyWith(
          isRevalidating: false,
          notice: showFailureNotice
              ? _buildNotice(
                  'Mostrando datos guardados (${fallback.message})',
                  BreedsNoticeKind.warning,
                )
              : null,
        ),
      );
    }
  }

  List<Breed> _mergeUniqueBreeds(List<Breed> existing, List<Breed> incoming) {
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
    await _connectivitySubscription?.cancel();
    for (final completer in List<Completer<void>>.of(_pendingRefreshCompleters)) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
    _pendingRefreshCompleters.clear();
    return super.close();
  }
}
