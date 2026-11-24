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
/// - Offline-first Stale-While-Revalidate (SWR) startup
/// - `droppable()` concurrency control on pagination and refresh
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
    on<BreedsRefreshed>(_onRefreshed, transformer: droppableTransformer());
    on<BreedsNextPageRequested>(
      _onNextPageRequested,
      transformer: droppableTransformer(),
    );
    on<BreedsSearchQueryChanged>(
      _onSearchQueryChanged,
      transformer: debounceTransformer(searchDebounceDuration),
    );
    on<BreedsConnectivityChanged>(_onConnectivityChanged);
    on<BreedsAppResumed>(_onAppResumed, transformer: droppableTransformer());
    on<BreedsNoticeCleared>(_onNoticeCleared);

    _connectivitySubscription = _connectivityMonitor.onStatusChanged.listen(
      (isOnline) => add(BreedsConnectivityChanged(isOnline: isOnline)),
    );
  }

  final BreedsRepository _repository;
  final ConnectivityMonitor _connectivityMonitor;
  final Duration _foregroundRevalidateThreshold;
  final DateTime Function() _clock;
  StreamSubscription<bool>? _connectivitySubscription;
  int _noticeCounter = 0;

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
    final isOnline = await _connectivityMonitor.hasConnection;
    final cached = _repository.getCachedFirstPage();

    if (cached != null && cached.page.items.isNotEmpty) {
      // Offline-first SWR: render cached page 1 instantaneously.
      emit(
        state.copyWith(
          status: BreedsStatus.loaded,
          breeds: cached.page.items,
          currentPage: cached.page.currentPage,
          lastPage: cached.page.lastPage,
          total: cached.page.total,
          isFromCache: true,
          isRevalidating: isOnline,
          isOnline: isOnline,
          lastSyncedAt: cached.cachedAt,
          errorMessage: null,
          paginationErrorMessage: null,
        ),
      );

      if (!isOnline) {
        return;
      }

      // Revalidate page 1 in background (always on cold start or when stale).
      await _revalidateFirstPage(emit, showFailureNotice: true);
      return;
    }

    // No local cache available: show loading skeleton and fetch page 1.
    emit(
      state.copyWith(
        status: BreedsStatus.loading,
        isOnline: isOnline,
        errorMessage: null,
        paginationErrorMessage: null,
      ),
    );

    try {
      final page = await _repository.fetchBreedsPage(page: 1);
      emit(
        state.copyWith(
          status: BreedsStatus.loaded,
          breeds: page.items,
          currentPage: page.currentPage,
          lastPage: page.lastPage,
          total: page.total,
          isFromCache: false,
          isRevalidating: false,
          isOnline: true,
          lastSyncedAt: _clock().toUtc(),
          errorMessage: null,
          paginationErrorMessage: null,
        ),
      );
    } on AppFailure catch (failure) {
      emit(
        state.copyWith(
          status: BreedsStatus.failure,
          isRevalidating: false,
          errorMessage: failure.message,
        ),
      );
    }
  }

  Future<void> _onRefreshed(
    BreedsRefreshed event,
    Emitter<BreedsState> emit,
  ) async {
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

    // Explicit cache invalidation on Pull-to-Refresh before fetching page 1.
    await _repository.invalidateCache();
    emit(
      state.copyWith(
        isOnline: true,
        isRevalidating: true,
        paginationErrorMessage: null,
      ),
    );

    try {
      final page = await _repository.fetchBreedsPage(page: 1);
      emit(
        state.copyWith(
          status: BreedsStatus.loaded,
          breeds: page.items,
          currentPage: page.currentPage,
          lastPage: page.lastPage,
          total: page.total,
          isFromCache: false,
          isRevalidating: false,
          lastSyncedAt: _clock().toUtc(),
          errorMessage: null,
          paginationErrorMessage: null,
        ),
      );
    } on AppFailure catch (failure) {
      if (state.breeds.isNotEmpty) {
        emit(
          state.copyWith(
            isRevalidating: false,
            notice: _buildNotice(
              'No se pudo actualizar: ${failure.message}',
              BreedsNoticeKind.error,
            ),
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: BreedsStatus.failure,
            isRevalidating: false,
            errorMessage: failure.message,
          ),
        );
      }
    }
  }

  Future<void> _onNextPageRequested(
    BreedsNextPageRequested event,
    Emitter<BreedsState> emit,
  ) async {
    if (state.status != BreedsStatus.loaded ||
        !state.hasMore ||
        state.isLoadingMore ||
        state.breeds.isEmpty) {
      return;
    }

    final nextPage = state.currentPage + 1;
    emit(
      state.copyWith(
        isLoadingMore: true,
        paginationErrorMessage: null,
      ),
    );

    try {
      final page = await _repository.fetchBreedsPage(page: nextPage);
      final merged = _mergeUniqueBreeds(state.breeds, page.items);

      emit(
        state.copyWith(
          breeds: merged,
          currentPage: page.currentPage,
          lastPage: page.lastPage,
          total: page.total,
          isLoadingMore: false,
          isOnline: true,
          paginationErrorMessage: null,
        ),
      );
    } on AppFailure catch (failure) {
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

    // Recovered connectivity: auto-recover stale cache or failed loads.
    emit(
      state.copyWith(
        isOnline: true,
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
    } else if (state.isFromCache) {
      await _revalidateFirstPage(emit, showFailureNotice: false);
    } else if (state.paginationErrorMessage != null && state.hasMore) {
      add(const BreedsNextPageRequested());
    }
  }

  Future<void> _onAppResumed(
    BreedsAppResumed event,
    Emitter<BreedsState> emit,
  ) async {
    if (state.status != BreedsStatus.loaded) {
      return;
    }

    final isOnline = await _connectivityMonitor.hasConnection;
    if (!isOnline) {
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

    if (state.currentPage <= 1) {
      await _revalidateFirstPage(emit, showFailureNotice: false);
    } else {
      // Refresh page 1 cache without disrupting deeper scroll progress.
      try {
        await _repository.fetchBreedsPage(page: 1);
        emit(
          state.copyWith(
            isRevalidating: false,
            isFromCache: false,
            lastSyncedAt: _clock().toUtc(),
          ),
        );
      } on AppFailure {
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
    required bool showFailureNotice,
  }) async {
    try {
      final freshPage = await _repository.fetchBreedsPage(page: 1);
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
    return super.close();
  }
}
