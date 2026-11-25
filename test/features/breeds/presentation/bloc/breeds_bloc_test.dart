import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:cat_directory_app/core/errors/app_failure.dart';
import 'package:cat_directory_app/core/network/connectivity_monitor.dart';
import 'package:cat_directory_app/features/breeds/domain/entities/breed.dart';
import 'package:cat_directory_app/features/breeds/domain/entities/breeds_page.dart';
import 'package:cat_directory_app/features/breeds/domain/entities/cached_breeds_result.dart';
import 'package:cat_directory_app/features/breeds/domain/entities/cat_fact.dart';
import 'package:cat_directory_app/features/breeds/domain/repositories/breeds_repository.dart';
import 'package:cat_directory_app/features/breeds/presentation/bloc/breed_detail_cubit.dart';
import 'package:cat_directory_app/features/breeds/presentation/bloc/breed_detail_state.dart';
import 'package:cat_directory_app/features/breeds/presentation/bloc/breeds_bloc.dart';
import 'package:cat_directory_app/features/breeds/presentation/bloc/breeds_event.dart';
import 'package:cat_directory_app/features/breeds/presentation/bloc/breeds_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockBreedsRepository extends Mock implements BreedsRepository {}

class _MockConnectivityMonitor extends Mock implements ConnectivityMonitor {}

void main() {
  const breed1 = Breed(
    breed: 'Abyssinian',
    country: 'Ethiopia',
    origin: 'Natural/Standard',
    coat: 'Short',
    pattern: 'Ticked',
  );
  const breed2 = Breed(
    breed: 'Aegean',
    country: 'Greece',
    origin: 'Natural/Standard',
    coat: 'Semi-long',
    pattern: 'Bi- or tri-colored',
  );
  const breed3 = Breed(
    breed: 'Bengal',
    country: 'United States',
    origin: 'Hybrid',
    coat: 'Short',
    pattern: 'Spotted',
  );
  const breed4 = Breed(
    breed: 'Siamese',
    country: 'Thailand',
    origin: 'Natural',
    coat: 'Short',
    pattern: 'Colorpoint',
  );

  final fixedNow = DateTime.utc(2026, 11, 24, 18);

  group('BreedsBloc', () {
    late _MockBreedsRepository repository;
    late _MockConnectivityMonitor connectivity;
    late StreamController<bool> connectivityController;

    setUp(() {
      repository = _MockBreedsRepository();
      connectivity = _MockConnectivityMonitor();
      connectivityController = StreamController<bool>.broadcast();

      when(() => connectivity.hasConnection).thenAnswer((_) async => true);
      when(() => connectivity.onStatusChanged)
          .thenAnswer((_) => connectivityController.stream);
      when(() => repository.getCachedFirstPage()).thenReturn(null);
    });

    tearDown(() async {
      await connectivityController.close();
    });

    blocTest<BreedsBloc, BreedsState>(
      'emits expired cached page immediately then revalidates from network (SWR)',
      setUp: () {
        when(() => repository.getCachedFirstPage()).thenReturn(
          CachedBreedsResult(
            page: const BreedsPage(
              currentPage: 1,
              lastPage: 3,
              total: 60,
              items: [breed1],
            ),
            cachedAt: fixedNow.subtract(const Duration(minutes: 11)),
            isExpired: true,
          ),
        );
        when(
          () => repository.fetchBreedsPage(
            page: 1,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer(
          (_) async => const BreedsPage(
            currentPage: 1,
            lastPage: 3,
            total: 60,
            items: [breed1, breed2],
          ),
        );
      },
      build: () => BreedsBloc(
        repository: repository,
        connectivityMonitor: connectivity,
        clock: () => fixedNow,
      ),
      act: (bloc) => bloc.add(const BreedsStarted()),
      expect: () => [
        isA<BreedsState>()
            .having((s) => s.status, 'status', BreedsStatus.loaded)
            .having((s) => s.breeds, 'breeds', [breed1])
            .having((s) => s.isFromCache, 'isFromCache', true)
            .having((s) => s.isRevalidating, 'isRevalidating', true),
        isA<BreedsState>()
            .having((s) => s.status, 'status', BreedsStatus.loaded)
            .having((s) => s.breeds, 'breeds', [breed1, breed2])
            .having((s) => s.isFromCache, 'isFromCache', false)
            .having((s) => s.isRevalidating, 'isRevalidating', false),
      ],
    );

    blocTest<BreedsBloc, BreedsState>(
      'uses fresh cache (< 10 min) online without redundant revalidation and clears stale banner',
      setUp: () {
        when(() => repository.getCachedFirstPage()).thenReturn(
          CachedBreedsResult(
            page: const BreedsPage(
              currentPage: 1,
              lastPage: 3,
              total: 60,
              items: [breed1, breed2],
            ),
            cachedAt: fixedNow.subtract(const Duration(minutes: 4)),
            isExpired: false,
          ),
        );
      },
      build: () => BreedsBloc(
        repository: repository,
        connectivityMonitor: connectivity,
        clock: () => fixedNow,
      ),
      act: (bloc) => bloc.add(const BreedsStarted()),
      expect: () => [
        isA<BreedsState>()
            .having((s) => s.status, 'status', BreedsStatus.loaded)
            .having((s) => s.breeds, 'breeds', [breed1, breed2])
            .having((s) => s.isFromCache, 'isFromCache', false)
            .having((s) => s.isRevalidating, 'isRevalidating', false)
            .having((s) => s.isOnline, 'isOnline', true),
      ],
      verify: (_) {
        verifyNever(
          () => repository.fetchBreedsPage(
            page: any(named: 'page'),
            cancelToken: any(named: 'cancelToken'),
          ),
        );
      },
    );

    blocTest<BreedsBloc, BreedsState>(
      'renders cached breeds synchronously before resolving offline status without calling remote API',
      setUp: () {
        when(() => connectivity.hasConnection).thenAnswer((_) async => false);
        when(() => repository.getCachedFirstPage()).thenReturn(
          CachedBreedsResult(
            page: const BreedsPage(
              currentPage: 1,
              lastPage: 2,
              total: 40,
              items: [breed1, breed2],
            ),
            cachedAt: fixedNow.subtract(const Duration(minutes: 2)),
            isExpired: false,
          ),
        );
      },
      build: () => BreedsBloc(
        repository: repository,
        connectivityMonitor: connectivity,
        clock: () => fixedNow,
      ),
      act: (bloc) => bloc.add(const BreedsStarted()),
      expect: () => [
        isA<BreedsState>()
            .having((s) => s.status, 'status', BreedsStatus.loaded)
            .having((s) => s.breeds, 'breeds', [breed1, breed2])
            .having((s) => s.errorMessage, 'errorMessage', isNull),
        isA<BreedsState>()
            .having((s) => s.status, 'status', BreedsStatus.loaded)
            .having((s) => s.breeds, 'breeds', [breed1, breed2])
            .having((s) => s.isFromCache, 'isFromCache', true)
            .having((s) => s.isOnline, 'isOnline', false)
            .having((s) => s.errorMessage, 'errorMessage', isNull),
      ],
      verify: (_) {
        verifyNever(
          () => repository.fetchBreedsPage(
            page: any(named: 'page'),
            cancelToken: any(named: 'cancelToken'),
          ),
        );
      },
    );

    test(
      'emits cached first page synchronously before connectivityMonitor.hasConnection resolves (M4)',
      () async {
        final hasConnectionCompleter = Completer<bool>();
        when(() => connectivity.hasConnection)
            .thenAnswer((_) => hasConnectionCompleter.future);
        when(() => repository.getCachedFirstPage()).thenReturn(
          CachedBreedsResult(
            page: const BreedsPage(
              currentPage: 1,
              lastPage: 2,
              total: 40,
              items: [breed1, breed2],
            ),
            cachedAt: fixedNow.subtract(const Duration(minutes: 1)),
            isExpired: false,
          ),
        );

        final bloc = BreedsBloc(
          repository: repository,
          connectivityMonitor: connectivity,
          clock: () => fixedNow,
        );
        addTearDown(bloc.close);

        final seenStatuses = <BreedsStatus>[];
        final sub = bloc.stream.listen((s) => seenStatuses.add(s.status));
        addTearDown(sub.cancel);

        bloc.add(const BreedsStarted());
        await bloc.stream.firstWhere((s) => s.status == BreedsStatus.loaded);

        expect(hasConnectionCompleter.isCompleted, isFalse);
        expect(bloc.state.status, BreedsStatus.loaded);
        expect(bloc.state.breeds, [breed1, breed2]);
        expect(seenStatuses, isNot(contains(BreedsStatus.loading)));

        hasConnectionCompleter.complete(false);
        await bloc.stream.firstWhere((s) => !s.isOnline);
        expect(bloc.state.isFromCache, isTrue);
      },
    );

    blocTest<BreedsBloc, BreedsState>(
      'drops concurrent pagination triggers via droppable() transformer',
      setUp: () {
        when(
          () => repository.fetchBreedsPage(
            page: 2,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 30));
          return const BreedsPage(
            currentPage: 2,
            lastPage: 3,
            total: 60,
            items: [breed3],
          );
        });
      },
      build: () => BreedsBloc(
        repository: repository,
        connectivityMonitor: connectivity,
      ),
      seed: () => const BreedsState(
        status: BreedsStatus.loaded,
        breeds: [breed1, breed2],
        currentPage: 1,
        lastPage: 3,
        total: 60,
      ),
      act: (bloc) {
        bloc
          ..add(const BreedsNextPageRequested())
          ..add(const BreedsNextPageRequested())
          ..add(const BreedsNextPageRequested());
      },
      wait: const Duration(milliseconds: 80),
      expect: () => [
        isA<BreedsState>()
            .having((s) => s.isLoadingMore, 'isLoadingMore', true),
        isA<BreedsState>()
            .having((s) => s.isLoadingMore, 'isLoadingMore', false)
            .having((s) => s.currentPage, 'currentPage', 2)
            .having((s) => s.breeds, 'breeds', [breed1, breed2, breed3]),
      ],
      verify: (_) {
        verify(
          () => repository.fetchBreedsPage(
            page: 2,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).called(1);
      },
    );

    blocTest<BreedsBloc, BreedsState>(
      'preserves loaded breeds when intermediate page fails',
      setUp: () {
        when(
          () => repository.fetchBreedsPage(
            page: 2,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(const NetworkFailure());
      },
      build: () => BreedsBloc(
        repository: repository,
        connectivityMonitor: connectivity,
      ),
      seed: () => const BreedsState(
        status: BreedsStatus.loaded,
        breeds: [breed1, breed2],
        currentPage: 1,
        lastPage: 3,
        total: 60,
      ),
      act: (bloc) => bloc.add(const BreedsNextPageRequested()),
      expect: () => [
        isA<BreedsState>()
            .having((s) => s.isLoadingMore, 'isLoadingMore', true)
            .having((s) => s.breeds, 'breeds', [breed1, breed2]),
        isA<BreedsState>()
            .having((s) => s.isLoadingMore, 'isLoadingMore', false)
            .having((s) => s.breeds, 'breeds', [breed1, breed2])
            .having((s) => s.paginationErrorMessage, 'paginationError', isNotNull),
      ],
    );

    blocTest<BreedsBloc, BreedsState>(
      'debounces local search query and filters in-memory breeds',
      build: () => BreedsBloc(
        repository: repository,
        connectivityMonitor: connectivity,
        searchDebounceDuration: const Duration(milliseconds: 40),
      ),
      seed: () => const BreedsState(
        status: BreedsStatus.loaded,
        breeds: [breed1, breed2, breed3],
        currentPage: 1,
        lastPage: 1,
        total: 3,
      ),
      act: (bloc) {
        bloc
          ..add(const BreedsSearchQueryChanged('b'))
          ..add(const BreedsSearchQueryChanged('be'))
          ..add(const BreedsSearchQueryChanged('ben'));
      },
      wait: const Duration(milliseconds: 90),
      expect: () => [
        isA<BreedsState>()
            .having((s) => s.searchQuery, 'searchQuery', 'ben')
            .having((s) => s.filteredBreeds, 'filteredBreeds', [breed3])
            .having((s) => s.breeds.length, 'base breeds preserved', 3),
      ],
    );

    blocTest<BreedsBloc, BreedsState>(
      'auto-revalidates cached list when connectivity transitions offline -> online',
      setUp: () {
        when(
          () => repository.fetchBreedsPage(
            page: 1,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer(
          (_) async => const BreedsPage(
            currentPage: 1,
            lastPage: 2,
            total: 40,
            items: [breed1, breed2],
          ),
        );
      },
      build: () => BreedsBloc(
        repository: repository,
        connectivityMonitor: connectivity,
        clock: () => fixedNow,
      ),
      seed: () => const BreedsState(
        status: BreedsStatus.loaded,
        breeds: [breed1],
        currentPage: 1,
        lastPage: 2,
        total: 40,
        isFromCache: true,
        isOnline: false,
      ),
      act: (_) => connectivityController.add(true),
      wait: const Duration(milliseconds: 50),
      expect: () => [
        isA<BreedsState>()
            .having((s) => s.isOnline, 'isOnline', true)
            .having((s) => s.isRevalidating, 'isRevalidating', true)
            .having((s) => s.notice?.kind, 'notice kind', BreedsNoticeKind.info)
            .having(
              (s) => s.notice?.message,
              'notice message',
              'Conexión restaurada. Sincronizando directorio...',
            ),
        isA<BreedsState>()
            .having((s) => s.isFromCache, 'isFromCache', false)
            .having((s) => s.isRevalidating, 'isRevalidating', false)
            .having((s) => s.breeds, 'breeds', [breed1, breed2]),
      ],
    );

    blocTest<BreedsBloc, BreedsState>(
      'clears isFromCache when next page loads successfully from network',
      setUp: () {
        when(
          () => repository.fetchBreedsPage(
            page: 2,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer(
          (_) async => const BreedsPage(
            currentPage: 2,
            lastPage: 3,
            total: 60,
            items: [breed3],
          ),
        );
      },
      build: () => BreedsBloc(
        repository: repository,
        connectivityMonitor: connectivity,
      ),
      seed: () => const BreedsState(
        status: BreedsStatus.loaded,
        breeds: [breed1, breed2],
        currentPage: 1,
        lastPage: 3,
        total: 60,
        isFromCache: true,
      ),
      act: (bloc) => bloc.add(const BreedsNextPageRequested()),
      expect: () => [
        isA<BreedsState>()
            .having((s) => s.isLoadingMore, 'isLoadingMore', true),
        isA<BreedsState>()
            .having((s) => s.isLoadingMore, 'isLoadingMore', false)
            .having((s) => s.isFromCache, 'isFromCache', false)
            .having((s) => s.currentPage, 'currentPage', 2)
            .having((s) => s.breeds, 'breeds', [breed1, breed2, breed3]),
      ],
    );

    blocTest<BreedsBloc, BreedsState>(
      'connectivity recovery updates page 1 slice while preserving deeper pagination when currentPage > 1',
      setUp: () {
        when(
          () => repository.fetchBreedsPage(
            page: 1,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer(
          (_) async => const BreedsPage(
            currentPage: 1,
            lastPage: 3,
            total: 60,
            items: [breed1],
          ),
        );
      },
      build: () => BreedsBloc(
        repository: repository,
        connectivityMonitor: connectivity,
        clock: () => fixedNow,
      ),
      seed: () => const BreedsState(
        status: BreedsStatus.loaded,
        breeds: [breed1, breed2, breed3],
        currentPage: 2,
        lastPage: 3,
        total: 60,
        isFromCache: true,
        isOnline: false,
      ),
      act: (_) => connectivityController.add(true),
      wait: const Duration(milliseconds: 50),
      expect: () => [
        isA<BreedsState>()
            .having((s) => s.isOnline, 'isOnline', true)
            .having((s) => s.isRevalidating, 'isRevalidating', true),
        isA<BreedsState>()
            .having((s) => s.isRevalidating, 'isRevalidating', false)
            .having((s) => s.isFromCache, 'isFromCache', false)
            .having((s) => s.currentPage, 'currentPage', 2)
            .having((s) => s.breeds, 'breeds', [breed1, breed2, breed3]),
      ],
    );

    test(
      'revalidation with currentPage > 1 merges updated page 1 slice and metadata while keeping page 2 items (M8)',
      () async {
        const updatedBreed1 = Breed(
          breed: 'Abyssinian',
          country: 'Updated Ethiopia',
          origin: 'Natural/Standard',
          coat: 'Short',
          pattern: 'Ticked',
        );
        when(
          () => repository.fetchBreedsPage(
            page: 1,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer(
          (_) async => const BreedsPage(
            currentPage: 1,
            lastPage: 4,
            total: 80,
            items: [updatedBreed1, breed4],
          ),
        );

        final bloc = BreedsBloc(
          repository: repository,
          connectivityMonitor: connectivity,
          clock: () => fixedNow,
        );
        addTearDown(bloc.close);

        bloc.emit(
          const BreedsState(
            status: BreedsStatus.loaded,
            breeds: [breed1, breed2, breed3],
            currentPage: 2,
            lastPage: 3,
            total: 60,
            isFromCache: true,
            isOnline: false,
          ),
        );

        final settled = bloc.stream.firstWhere(
          (s) => !s.isRevalidating && !s.isFromCache,
        );
        connectivityController.add(true);
        await settled;

        expect(bloc.state.currentPage, 2);
        expect(bloc.state.lastPage, 4);
        expect(bloc.state.total, 80);
        expect(bloc.state.breeds, [updatedBreed1, breed4, breed2, breed3]);
      },
    );

    group('BreedsRefreshed', () {
      test(
        'reloads page 1 atomically without invalidating cache first and completes Completer',
        () async {
          when(
            () => repository.fetchBreedsPage(
              page: 1,
              cancelToken: any(named: 'cancelToken'),
            ),
          ).thenAnswer(
            (_) async => const BreedsPage(
              currentPage: 1,
              lastPage: 2,
              total: 40,
              items: [breed1, breed2],
            ),
          );

          final bloc = BreedsBloc(
            repository: repository,
            connectivityMonitor: connectivity,
            clock: () => fixedNow,
          );
          addTearDown(bloc.close);

          bloc.emit(
            const BreedsState(
              status: BreedsStatus.loaded,
              breeds: [breed1],
              currentPage: 1,
              lastPage: 2,
              total: 40,
              isFromCache: true,
            ),
          );

          final completer = Completer<void>();
          bloc.add(BreedsRefreshed(completer: completer));
          await completer.future;

          expect(bloc.state.status, BreedsStatus.loaded);
          expect(bloc.state.breeds, [breed1, breed2]);
          expect(bloc.state.isFromCache, isFalse);
          expect(bloc.state.isRevalidating, isFalse);
          expect(bloc.state.lastSyncedAt, fixedNow);
          verifyNever(() => repository.invalidateCache());
        },
      );

      test(
        'preserves cached data, emits warning notice and completes Completer when offline',
        () async {
          when(() => connectivity.hasConnection).thenAnswer((_) async => false);

          final bloc = BreedsBloc(
            repository: repository,
            connectivityMonitor: connectivity,
          );
          addTearDown(bloc.close);

          bloc.emit(
            const BreedsState(
              status: BreedsStatus.loaded,
              breeds: [breed1],
              currentPage: 1,
              lastPage: 2,
              total: 40,
              isFromCache: true,
            ),
          );

          final completer = Completer<void>();
          bloc.add(BreedsRefreshed(completer: completer));
          await completer.future;

          expect(bloc.state.isOnline, isFalse);
          expect(bloc.state.isRevalidating, isFalse);
          expect(bloc.state.breeds, [breed1]);
          expect(bloc.state.notice?.kind, BreedsNoticeKind.warning);
          expect(
            bloc.state.notice?.message,
            'Sin conexión a internet. Mostrando los datos guardados.',
          );
          verifyNever(() => repository.invalidateCache());
          verifyNever(
            () => repository.fetchBreedsPage(
              page: any(named: 'page'),
              cancelToken: any(named: 'cancelToken'),
            ),
          );
        },
      );

      test(
        'preserves existing breeds and offline cache when remote refresh fails',
        () async {
          when(
            () => repository.fetchBreedsPage(
              page: 1,
              cancelToken: any(named: 'cancelToken'),
            ),
          ).thenThrow(const NetworkFailure());

          final bloc = BreedsBloc(
            repository: repository,
            connectivityMonitor: connectivity,
          );
          addTearDown(bloc.close);

          bloc.emit(
            const BreedsState(
              status: BreedsStatus.loaded,
              breeds: [breed1, breed2],
              currentPage: 1,
              lastPage: 2,
              total: 40,
              isFromCache: true,
            ),
          );

          final completer = Completer<void>();
          bloc.add(BreedsRefreshed(completer: completer));
          await completer.future;

          expect(bloc.state.status, BreedsStatus.loaded);
          expect(bloc.state.breeds, [breed1, breed2]);
          expect(bloc.state.isRevalidating, isFalse);
          expect(bloc.state.notice?.kind, BreedsNoticeKind.error);
          verifyNever(() => repository.invalidateCache());
        },
      );

      test(
        'shares completion across concurrent BreedsRefreshed calls without closing RefreshIndicator early (M8)',
        () async {
          final page1Completer = Completer<BreedsPage>();
          when(
            () => repository.fetchBreedsPage(
              page: 1,
              cancelToken: any(named: 'cancelToken'),
            ),
          ).thenAnswer((_) => page1Completer.future);

          final bloc = BreedsBloc(
            repository: repository,
            connectivityMonitor: connectivity,
          );
          addTearDown(bloc.close);

          bloc.emit(
            const BreedsState(
              status: BreedsStatus.loaded,
              breeds: [breed1],
              currentPage: 1,
              lastPage: 2,
              total: 40,
            ),
          );

          final firstRefresh = Completer<void>();
          final secondRefresh = Completer<void>();

          bloc
            ..add(BreedsRefreshed(completer: firstRefresh))
            ..add(BreedsRefreshed(completer: secondRefresh));

          await bloc.stream.firstWhere((s) => s.isRevalidating);
          await Future<void>.delayed(const Duration(milliseconds: 20));

          // Neither completer should finish until the single in-flight refresh completes.
          expect(firstRefresh.isCompleted, isFalse);
          expect(secondRefresh.isCompleted, isFalse);

          page1Completer.complete(
            const BreedsPage(
              currentPage: 1,
              lastPage: 2,
              total: 40,
              items: [breed1, breed2],
            ),
          );
          await Future.wait([
            firstRefresh.future.timeout(const Duration(seconds: 1)),
            secondRefresh.future.timeout(const Duration(seconds: 1)),
          ]);

          verify(
            () => repository.fetchBreedsPage(
              page: 1,
              cancelToken: any(named: 'cancelToken'),
            ),
          ).called(1);
          expect(bloc.state.breeds, [breed1, breed2]);
        },
      );
    });

    group('BreedsAppResumed', () {
      blocTest<BreedsBloc, BreedsState>(
        'skips revalidation when backgroundDuration < threshold and cache is fresh',
        setUp: () {
          when(() => repository.getCachedFirstPage()).thenReturn(
            CachedBreedsResult(
              page: const BreedsPage(
                currentPage: 1,
                lastPage: 2,
                total: 40,
                items: [breed1],
              ),
              cachedAt: fixedNow.subtract(const Duration(minutes: 2)),
              isExpired: false,
            ),
          );
        },
        build: () => BreedsBloc(
          repository: repository,
          connectivityMonitor: connectivity,
          foregroundRevalidateThreshold: const Duration(minutes: 5),
        ),
        seed: () => const BreedsState(
          status: BreedsStatus.loaded,
          breeds: [breed1],
          currentPage: 1,
          lastPage: 2,
          total: 40,
        ),
        act: (bloc) => bloc.add(
          const BreedsAppResumed(backgroundDuration: Duration(minutes: 2)),
        ),
        expect: () => <BreedsState>[],
        verify: (_) {
          verifyNever(
            () => repository.fetchBreedsPage(
              page: any(named: 'page'),
              cancelToken: any(named: 'cancelToken'),
            ),
          );
        },
      );

      blocTest<BreedsBloc, BreedsState>(
        'revalidates page 1 when backgroundDuration meets threshold on page 1',
        setUp: () {
          when(() => repository.getCachedFirstPage()).thenReturn(
            CachedBreedsResult(
              page: const BreedsPage(
                currentPage: 1,
                lastPage: 2,
                total: 40,
                items: [breed1],
              ),
              cachedAt: fixedNow.subtract(const Duration(minutes: 6)),
              isExpired: false,
            ),
          );
          when(
            () => repository.fetchBreedsPage(
              page: 1,
              cancelToken: any(named: 'cancelToken'),
            ),
          ).thenAnswer(
            (_) async => const BreedsPage(
              currentPage: 1,
              lastPage: 2,
              total: 40,
              items: [breed1, breed2],
            ),
          );
        },
        build: () => BreedsBloc(
          repository: repository,
          connectivityMonitor: connectivity,
          foregroundRevalidateThreshold: const Duration(minutes: 5),
          clock: () => fixedNow,
        ),
        seed: () => const BreedsState(
          status: BreedsStatus.loaded,
          breeds: [breed1],
          currentPage: 1,
          lastPage: 2,
          total: 40,
        ),
        act: (bloc) => bloc.add(
          const BreedsAppResumed(backgroundDuration: Duration(minutes: 6)),
        ),
        expect: () => [
          isA<BreedsState>()
              .having((s) => s.isRevalidating, 'isRevalidating', true),
          isA<BreedsState>()
              .having((s) => s.isRevalidating, 'isRevalidating', false)
              .having((s) => s.isFromCache, 'isFromCache', false)
              .having((s) => s.breeds, 'breeds', [breed1, breed2])
              .having((s) => s.lastSyncedAt, 'lastSyncedAt', fixedNow),
        ],
      );

      blocTest<BreedsBloc, BreedsState>(
        'refreshes cache without overwriting loaded pages when currentPage > 1',
        setUp: () {
          when(() => repository.getCachedFirstPage()).thenReturn(
            CachedBreedsResult(
              page: const BreedsPage(
                currentPage: 1,
                lastPage: 3,
                total: 60,
                items: [breed1],
              ),
              cachedAt: fixedNow.subtract(const Duration(minutes: 12)),
              isExpired: true,
            ),
          );
          when(
            () => repository.fetchBreedsPage(
              page: 1,
              cancelToken: any(named: 'cancelToken'),
            ),
          ).thenAnswer(
            (_) async => const BreedsPage(
              currentPage: 1,
              lastPage: 3,
              total: 60,
              items: [breed1],
            ),
          );
        },
        build: () => BreedsBloc(
          repository: repository,
          connectivityMonitor: connectivity,
          clock: () => fixedNow,
        ),
        seed: () => const BreedsState(
          status: BreedsStatus.loaded,
          breeds: [breed1, breed2, breed3],
          currentPage: 2,
          lastPage: 3,
          total: 60,
        ),
        act: (bloc) => bloc.add(
          const BreedsAppResumed(backgroundDuration: Duration(minutes: 1)),
        ),
        expect: () => [
          isA<BreedsState>()
              .having((s) => s.isRevalidating, 'isRevalidating', true),
          isA<BreedsState>()
              .having((s) => s.isRevalidating, 'isRevalidating', false)
              .having((s) => s.currentPage, 'currentPage', 2)
              .having((s) => s.breeds, 'breeds', [breed1, breed2, breed3])
              .having((s) => s.lastSyncedAt, 'lastSyncedAt', fixedNow),
        ],
      );
    });

    group('Race condition prevention & CancelToken', () {
      test(
        'in-flight SWR revalidation does not overwrite page 2 loaded while revalidating',
        () async {
          final swrCompleter = Completer<BreedsPage>();
          when(() => repository.getCachedFirstPage()).thenReturn(
            CachedBreedsResult(
              page: const BreedsPage(
                currentPage: 1,
                lastPage: 3,
                total: 60,
                items: [breed1],
              ),
              cachedAt: fixedNow.subtract(const Duration(minutes: 15)),
              isExpired: true,
            ),
          );
          when(
            () => repository.fetchBreedsPage(
              page: 1,
              cancelToken: any(named: 'cancelToken'),
            ),
          ).thenAnswer((_) => swrCompleter.future);
          when(
            () => repository.fetchBreedsPage(
              page: 2,
              cancelToken: any(named: 'cancelToken'),
            ),
          ).thenAnswer(
            (_) async => const BreedsPage(
              currentPage: 2,
              lastPage: 3,
              total: 60,
              items: [breed2, breed3],
            ),
          );

          final bloc = BreedsBloc(
            repository: repository,
            connectivityMonitor: connectivity,
            clock: () => fixedNow,
          );
          addTearDown(bloc.close);

          bloc.add(const BreedsStarted());
          await bloc.stream.firstWhere(
            (s) => s.status == BreedsStatus.loaded && s.isRevalidating,
          );

          bloc.add(const BreedsNextPageRequested());
          await bloc.stream.firstWhere((s) => s.currentPage == 2);

          expect(bloc.state.breeds, [breed1, breed2, breed3]);

          // SWR finishes after page 2 is already loaded.
          swrCompleter.complete(
            const BreedsPage(
              currentPage: 1,
              lastPage: 3,
              total: 60,
              items: [breed1],
            ),
          );
          await bloc.stream.firstWhere((s) => !s.isRevalidating);

          expect(bloc.state.currentPage, 2);
          expect(bloc.state.breeds, [breed1, breed2, breed3]);
          expect(bloc.state.isFromCache, isFalse);
          expect(bloc.state.lastSyncedAt, fixedNow);
        },
      );

      test(
        'stale page 3 response is discarded after Pull-to-Refresh resets to page 1',
        () async {
          final page3Completer = Completer<BreedsPage>();
          CancelToken? capturedPage3Token;
          when(
            () => repository.fetchBreedsPage(
              page: 3,
              cancelToken: any(named: 'cancelToken'),
            ),
          ).thenAnswer((invocation) {
            capturedPage3Token =
                invocation.namedArguments[#cancelToken] as CancelToken?;
            return page3Completer.future;
          });
          when(
            () => repository.fetchBreedsPage(
              page: 1,
              cancelToken: any(named: 'cancelToken'),
            ),
          ).thenAnswer(
            (_) async => const BreedsPage(
              currentPage: 1,
              lastPage: 3,
              total: 60,
              items: [breed1],
            ),
          );

          final bloc = BreedsBloc(
            repository: repository,
            connectivityMonitor: connectivity,
            clock: () => fixedNow,
          );
          addTearDown(bloc.close);

          bloc.emit(
            const BreedsState(
              status: BreedsStatus.loaded,
              breeds: [breed1, breed2],
              currentPage: 2,
              lastPage: 3,
              total: 60,
            ),
          );

          bloc.add(const BreedsNextPageRequested());
          await bloc.stream.firstWhere((s) => s.isLoadingMore);

          final refreshCompleter = Completer<void>();
          bloc.add(BreedsRefreshed(completer: refreshCompleter));
          await refreshCompleter.future;

          expect(capturedPage3Token?.isCancelled, isTrue);
          expect(bloc.state.currentPage, 1);
          expect(bloc.state.breeds, [breed1]);
          expect(bloc.state.isLoadingMore, isFalse);

          // Late page 3 arrives after page 1 refresh completed.
          page3Completer.complete(
            const BreedsPage(
              currentPage: 3,
              lastPage: 3,
              total: 60,
              items: [breed3],
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 30));

          expect(bloc.state.currentPage, 1);
          expect(bloc.state.breeds, [breed1]);
        },
      );

      test(
        'BreedsNextPageRequested succeeds immediately after refresh cancels in-flight page 2 (A3)',
        () async {
          final stuckPage2Completer = Completer<BreedsPage>();
          final page2Tokens = <CancelToken?>[];
          var page2Calls = 0;

          when(
            () => repository.fetchBreedsPage(
              page: 2,
              cancelToken: any(named: 'cancelToken'),
            ),
          ).thenAnswer((invocation) {
            page2Calls++;
            page2Tokens.add(
              invocation.namedArguments[#cancelToken] as CancelToken?,
            );
            if (page2Calls == 1) {
              return stuckPage2Completer.future;
            }
            return Future<BreedsPage>.value(
              const BreedsPage(
                currentPage: 2,
                lastPage: 3,
                total: 60,
                items: [breed3],
              ),
            );
          });
          when(
            () => repository.fetchBreedsPage(
              page: 1,
              cancelToken: any(named: 'cancelToken'),
            ),
          ).thenAnswer(
            (_) async => const BreedsPage(
              currentPage: 1,
              lastPage: 3,
              total: 60,
              items: [breed4],
            ),
          );

          final bloc = BreedsBloc(
            repository: repository,
            connectivityMonitor: connectivity,
            clock: () => fixedNow,
          );
          addTearDown(bloc.close);

          bloc.emit(
            const BreedsState(
              status: BreedsStatus.loaded,
              breeds: [breed1, breed2],
              currentPage: 1,
              lastPage: 3,
              total: 60,
            ),
          );

          // Start stuck page 2 request.
          bloc.add(const BreedsNextPageRequested());
          await bloc.stream.firstWhere((s) => s.isLoadingMore);

          // Pull-to-refresh cancels stuck page 2 and reloads page 1.
          final refreshCompleter = Completer<void>();
          bloc.add(BreedsRefreshed(completer: refreshCompleter));
          await refreshCompleter.future;

          expect(page2Tokens.first?.isCancelled, isTrue);
          expect(bloc.state.breeds, [breed4]);
          expect(bloc.state.notice, isNull);

          // Immediately request page 2 again while old stuck future never resolved.
          final page2Loaded = bloc.stream
              .firstWhere((s) => s.currentPage == 2 && !s.isLoadingMore)
              .timeout(const Duration(seconds: 1));
          bloc.add(const BreedsNextPageRequested());
          await page2Loaded;

          expect(page2Calls, 2);
          expect(bloc.state.currentPage, 2);
          expect(bloc.state.breeds, [breed4, breed3]);
        },
      );

      test(
        'closing BreedsBloc cancels active pagination and first-page CancelTokens',
        () async {
          final stuckPage2 = Completer<BreedsPage>();
          CancelToken? paginationToken;

          when(
            () => repository.fetchBreedsPage(
              page: 2,
              cancelToken: any(named: 'cancelToken'),
            ),
          ).thenAnswer((invocation) {
            paginationToken =
                invocation.namedArguments[#cancelToken] as CancelToken?;
            return stuckPage2.future;
          });

          final bloc = BreedsBloc(
            repository: repository,
            connectivityMonitor: connectivity,
          );
          bloc.emit(
            const BreedsState(
              status: BreedsStatus.loaded,
              breeds: [breed1],
              currentPage: 1,
              lastPage: 2,
              total: 40,
            ),
          );

          bloc.add(const BreedsNextPageRequested());
          await bloc.stream.firstWhere((s) => s.isLoadingMore);
          expect(paginationToken?.isCancelled, isFalse);

          await bloc.close();
          expect(paginationToken?.isCancelled, isTrue);
        },
      );
    });

    group('Offline & reconnection messaging accuracy (M6)', () {
      test(
        'BreedsRefreshed while offline with empty breeds does not claim saved data',
        () async {
          when(() => connectivity.hasConnection).thenAnswer((_) async => false);

          final bloc = BreedsBloc(
            repository: repository,
            connectivityMonitor: connectivity,
          );
          addTearDown(bloc.close);

          bloc.emit(
            const BreedsState(
              status: BreedsStatus.failure,
              breeds: [],
              isOnline: false,
              errorMessage: 'Sin conexión a internet.',
            ),
          );

          final completer = Completer<void>();
          bloc.add(BreedsRefreshed(completer: completer));
          await completer.future;

          expect(bloc.state.notice?.kind, BreedsNoticeKind.warning);
          expect(
            bloc.state.notice?.message.toLowerCase(),
            isNot(contains('datos guardados')),
          );
          expect(bloc.state.notice?.message, const NetworkFailure().message);
        },
      );

      blocTest<BreedsBloc, BreedsState>(
        'cold-start offline connectivity event emits no misleading connection-lost notice',
        build: () => BreedsBloc(
          repository: repository,
          connectivityMonitor: connectivity,
        ),
        act: (_) => connectivityController.add(false),
        wait: const Duration(milliseconds: 20),
        expect: () => [
          isA<BreedsState>()
              .having((s) => s.isOnline, 'isOnline', false)
              .having((s) => s.notice, 'notice', isNull),
        ],
      );

      blocTest<BreedsBloc, BreedsState>(
        'reconnection with fresh loaded data emits Conexión restaurada without Sincronizando',
        build: () => BreedsBloc(
          repository: repository,
          connectivityMonitor: connectivity,
        ),
        seed: () => const BreedsState(
          status: BreedsStatus.loaded,
          breeds: [breed1, breed2],
          currentPage: 1,
          lastPage: 2,
          total: 40,
          isFromCache: false,
          isOnline: false,
        ),
        act: (_) => connectivityController.add(true),
        wait: const Duration(milliseconds: 20),
        expect: () => [
          isA<BreedsState>()
              .having((s) => s.isOnline, 'isOnline', true)
              .having((s) => s.isRevalidating, 'isRevalidating', false)
              .having((s) => s.notice?.kind, 'kind', BreedsNoticeKind.info)
              .having(
                (s) => s.notice?.message,
                'message',
                'Conexión restaurada.',
              ),
        ],
        verify: (_) {
          verifyNever(
            () => repository.fetchBreedsPage(
              page: any(named: 'page'),
              cancelToken: any(named: 'cancelToken'),
            ),
          );
        },
      );

      test(
        'reconnection does not auto-retry non-retryable AppFailure (B2 isRetryable integration)',
        () async {
          when(
            () => repository.fetchBreedsPage(
              page: 1,
              cancelToken: any(named: 'cancelToken'),
            ),
          ).thenThrow(const NotFoundFailure());

          final bloc = BreedsBloc(
            repository: repository,
            connectivityMonitor: connectivity,
          );
          addTearDown(bloc.close);

          bloc.add(const BreedsStarted());
          await bloc.stream.firstWhere((s) => s.status == BreedsStatus.failure);

          connectivityController.add(false);
          await bloc.stream.firstWhere((s) => !s.isOnline);

          connectivityController.add(true);
          await bloc.stream.firstWhere((s) => s.isOnline);
          await Future<void>.delayed(const Duration(milliseconds: 20));

          expect(bloc.state.notice?.message, 'Conexión restaurada.');
          verify(
            () => repository.fetchBreedsPage(
              page: 1,
              cancelToken: any(named: 'cancelToken'),
            ),
          ).called(1);
        },
      );
    });

    group('Defensive non-AppFailure exception handling', () {
      blocTest<BreedsBloc, BreedsState>(
        'recovers to failure when connectivityMonitor throws unexpected error on start',
        setUp: () {
          when(() => connectivity.hasConnection)
              .thenThrow(StateError('connectivity plugin error'));
        },
        build: () => BreedsBloc(
          repository: repository,
          connectivityMonitor: connectivity,
        ),
        act: (bloc) => bloc.add(const BreedsStarted()),
        expect: () => [
          isA<BreedsState>()
              .having((s) => s.status, 'status', BreedsStatus.failure)
              .having((s) => s.isRevalidating, 'isRevalidating', false)
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ],
      );

      blocTest<BreedsBloc, BreedsState>(
        'exits loading state cleanly when fetchBreedsPage throws non-AppFailure',
        setUp: () {
          when(
            () => repository.fetchBreedsPage(
              page: 1,
              cancelToken: any(named: 'cancelToken'),
            ),
          ).thenThrow(Exception('SharedPreferences write failed'));
        },
        build: () => BreedsBloc(
          repository: repository,
          connectivityMonitor: connectivity,
        ),
        act: (bloc) => bloc.add(const BreedsStarted()),
        expect: () => [
          isA<BreedsState>()
              .having((s) => s.status, 'status', BreedsStatus.loading),
          isA<BreedsState>()
              .having((s) => s.status, 'status', BreedsStatus.failure)
              .having((s) => s.errorMessage, 'errorMessage', isNotNull),
        ],
      );

      test(
        'catches unexpected errors in BreedsRefreshed and still completes Completer',
        () async {
          when(() => connectivity.hasConnection)
              .thenThrow(StateError('unexpected'));

          final bloc = BreedsBloc(
            repository: repository,
            connectivityMonitor: connectivity,
          );
          addTearDown(bloc.close);

          bloc.emit(
            const BreedsState(
              status: BreedsStatus.loaded,
              breeds: [breed1],
              currentPage: 1,
              lastPage: 2,
              total: 40,
            ),
          );

          final completer = Completer<void>();
          bloc.add(BreedsRefreshed(completer: completer));
          await completer.future.timeout(const Duration(seconds: 1));

          expect(bloc.state.status, BreedsStatus.loaded);
          expect(bloc.state.breeds, [breed1]);
          expect(bloc.state.isRevalidating, isFalse);
          expect(bloc.state.notice?.kind, BreedsNoticeKind.error);
        },
      );

      blocTest<BreedsBloc, BreedsState>(
        'resets isLoadingMore on unexpected error in BreedsNextPageRequested',
        setUp: () {
          when(
            () => repository.fetchBreedsPage(
              page: 2,
              cancelToken: any(named: 'cancelToken'),
            ),
          ).thenThrow(StateError('unexpected pagination error'));
        },
        build: () => BreedsBloc(
          repository: repository,
          connectivityMonitor: connectivity,
        ),
        seed: () => const BreedsState(
          status: BreedsStatus.loaded,
          breeds: [breed1],
          currentPage: 1,
          lastPage: 3,
          total: 60,
        ),
        act: (bloc) => bloc.add(const BreedsNextPageRequested()),
        expect: () => [
          isA<BreedsState>()
              .having((s) => s.isLoadingMore, 'isLoadingMore', true),
          isA<BreedsState>()
              .having((s) => s.isLoadingMore, 'isLoadingMore', false)
              .having((s) => s.breeds, 'breeds', [breed1])
              .having(
                (s) => s.paginationErrorMessage,
                'paginationErrorMessage',
                isNotNull,
              ),
        ],
      );
    });
  });

  group('BreedDetailCubit', () {
    const sampleFact = CatFact(
      fact: 'Cats have 32 muscles in each ear.',
      length: 33,
    );

    late _MockBreedsRepository repository;

    setUp(() {
      repository = _MockBreedsRepository();
    });

    blocTest<BreedDetailCubit, BreedDetailState>(
      'keeps breed details loaded even when independent /fact endpoint fails',
      setUp: () {
        when(
          () => repository.fetchRandomFact(
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(const NetworkFailure());
      },
      build: () => BreedDetailCubit(repository: repository),
      act: (cubit) => cubit.load(
        breedName: breed1.breed,
        initialBreed: breed1,
      ),
      verify: (cubit) {
        expect(cubit.state.breedStatus, BreedDetailStatus.loaded);
        expect(cubit.state.breed, breed1);
        expect(cubit.state.factStatus, CatFactStatus.failure);
        expect(cubit.state.factErrorMessage, isNotNull);
      },
    );

    blocTest<BreedDetailCubit, BreedDetailState>(
      'resolves breed on cold start (initialBreed: null) alongside random fact',
      setUp: () {
        when(
          () => repository.findBreedByName(
            breed3.breed,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => breed3);
        when(
          () => repository.fetchRandomFact(
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => sampleFact);
      },
      build: () => BreedDetailCubit(repository: repository),
      act: (cubit) => cubit.load(breedName: breed3.breed),
      expect: () => [
        isA<BreedDetailState>()
            .having((s) => s.factStatus, 'factStatus', CatFactStatus.loading),
        isA<BreedDetailState>()
            .having((s) => s.breedStatus, 'breedStatus', BreedDetailStatus.loading)
            .having((s) => s.factStatus, 'factStatus', CatFactStatus.loading),
        isA<BreedDetailState>()
            .having((s) => s.breedStatus, 'breedStatus', BreedDetailStatus.loading)
            .having((s) => s.factStatus, 'factStatus', CatFactStatus.loaded)
            .having((s) => s.fact, 'fact', sampleFact),
        isA<BreedDetailState>()
            .having((s) => s.breedStatus, 'breedStatus', BreedDetailStatus.loaded)
            .having((s) => s.breed, 'breed', breed3)
            .having((s) => s.breedErrorMessage, 'breedErrorMessage', isNull)
            .having((s) => s.factStatus, 'factStatus', CatFactStatus.loaded)
            .having((s) => s.fact, 'fact', sampleFact),
      ],
      verify: (_) {
        verify(
          () => repository.findBreedByName(
            breed3.breed,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).called(1);
        verify(
          () => repository.fetchRandomFact(
            cancelToken: any(named: 'cancelToken'),
          ),
        ).called(1);
      },
    );

    blocTest<BreedDetailCubit, BreedDetailState>(
      'emits failure state on cold start when findBreedByName throws AppFailure',
      setUp: () {
        when(
          () => repository.findBreedByName(
            'UnknownBreed',
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(
          const NotFoundFailure(message: 'Raza no encontrada.'),
        );
        when(
          () => repository.fetchRandomFact(
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => sampleFact);
      },
      build: () => BreedDetailCubit(repository: repository),
      act: (cubit) => cubit.load(breedName: 'UnknownBreed'),
      verify: (cubit) {
        expect(cubit.state.breedStatus, BreedDetailStatus.failure);
        expect(cubit.state.breed, isNull);
        expect(cubit.state.breedErrorMessage, 'Raza no encontrada.');
        expect(cubit.state.factStatus, CatFactStatus.loaded);
      },
    );

    blocTest<BreedDetailCubit, BreedDetailState>(
      'defensively catches non-AppFailure Object errors in breed lookup and fact loading',
      setUp: () {
        when(
          () => repository.findBreedByName(
            breed1.breed,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(StateError('unexpected lookup failure'));
        when(
          () => repository.fetchRandomFact(
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenThrow(const FormatException('corrupt fact payload'));
      },
      build: () => BreedDetailCubit(repository: repository),
      act: (cubit) => cubit.load(breedName: breed1.breed),
      verify: (cubit) {
        expect(cubit.state.breedStatus, BreedDetailStatus.failure);
        expect(
          cubit.state.breedErrorMessage,
          const UnknownFailure().message,
        );
        expect(cubit.state.factStatus, CatFactStatus.failure);
        expect(
          cubit.state.factErrorMessage,
          const UnknownFailure().message,
        );
      },
    );

    blocTest<BreedDetailCubit, BreedDetailState>(
      'retryBreedLookup recovers from cold-start error and clears error message',
      setUp: () {
        var calls = 0;
        when(
          () => repository.findBreedByName(
            breed3.breed,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async {
          calls++;
          if (calls == 1) {
            throw const NetworkFailure();
          }
          return breed3;
        });
        when(
          () => repository.fetchRandomFact(
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async => sampleFact);
      },
      build: () => BreedDetailCubit(repository: repository),
      act: (cubit) async {
        await cubit.load(breedName: breed3.breed);
        await cubit.retryBreedLookup(breed3.breed);
      },
      verify: (cubit) {
        expect(cubit.state.breedStatus, BreedDetailStatus.loaded);
        expect(cubit.state.breed, breed3);
        expect(cubit.state.breedErrorMessage, isNull);
        verify(
          () => repository.findBreedByName(
            breed3.breed,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).called(2);
      },
    );

    test('close() cancels in-flight /fact and deep-link breed lookup CancelTokens (B4)',
        () async {
      final breedCompleter = Completer<Breed>();
      final factCompleter = Completer<CatFact>();
      CancelToken? lookupToken;
      CancelToken? factToken;

      when(
        () => repository.findBreedByName(
          breed3.breed,
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((invocation) {
        lookupToken = invocation.namedArguments[#cancelToken] as CancelToken?;
        return breedCompleter.future;
      });
      when(
        () => repository.fetchRandomFact(
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((invocation) {
        factToken = invocation.namedArguments[#cancelToken] as CancelToken?;
        return factCompleter.future;
      });

      final cubit = BreedDetailCubit(repository: repository);
      unawaited(cubit.load(breedName: breed3.breed));
      await Future<void>.delayed(Duration.zero);

      expect(lookupToken, isNotNull);
      expect(factToken, isNotNull);
      expect(lookupToken!.isCancelled, isFalse);
      expect(factToken!.isCancelled, isFalse);

      await cubit.close();

      expect(lookupToken!.isCancelled, isTrue);
      expect(factToken!.isCancelled, isTrue);
    });
  });
}
