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
        when(() => repository.fetchBreedsPage(page: 1)).thenAnswer(
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
        verifyNever(() => repository.fetchBreedsPage(page: any(named: 'page')));
      },
    );

    blocTest<BreedsBloc, BreedsState>(
      'renders cached breeds instantly offline without calling remote API',
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
            .having((s) => s.isFromCache, 'isFromCache', true)
            .having((s) => s.isOnline, 'isOnline', false)
            .having((s) => s.errorMessage, 'errorMessage', isNull),
      ],
      verify: (_) {
        verifyNever(() => repository.fetchBreedsPage(page: any(named: 'page')));
      },
    );

    blocTest<BreedsBloc, BreedsState>(
      'drops concurrent pagination triggers via droppable() transformer',
      setUp: () {
        when(() => repository.fetchBreedsPage(page: 2)).thenAnswer((_) async {
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
        verify(() => repository.fetchBreedsPage(page: 2)).called(1);
      },
    );

    blocTest<BreedsBloc, BreedsState>(
      'preserves loaded breeds when intermediate page fails',
      setUp: () {
        when(() => repository.fetchBreedsPage(page: 2))
            .thenThrow(const NetworkFailure());
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
        when(() => repository.fetchBreedsPage(page: 1)).thenAnswer(
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
            .having((s) => s.notice?.kind, 'notice kind', BreedsNoticeKind.info),
        isA<BreedsState>()
            .having((s) => s.isFromCache, 'isFromCache', false)
            .having((s) => s.isRevalidating, 'isRevalidating', false)
            .having((s) => s.breeds, 'breeds', [breed1, breed2]),
      ],
    );

    blocTest<BreedsBloc, BreedsState>(
      'clears isFromCache when next page loads successfully from network',
      setUp: () {
        when(() => repository.fetchBreedsPage(page: 2)).thenAnswer(
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
      'connectivity recovery protects deeper pagination when currentPage > 1',
      setUp: () {
        when(() => repository.fetchBreedsPage(page: 1)).thenAnswer(
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

    group('BreedsRefreshed', () {
      test(
        'reloads page 1 atomically without invalidating cache first and completes Completer',
        () async {
          when(() => repository.fetchBreedsPage(page: 1)).thenAnswer(
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
          verifyNever(() => repository.invalidateCache());
          verifyNever(() => repository.fetchBreedsPage(page: any(named: 'page')));
        },
      );

      test(
        'preserves existing breeds and offline cache when remote refresh fails',
        () async {
          when(() => repository.fetchBreedsPage(page: 1))
              .thenThrow(const NetworkFailure());

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
        'completes discarded Completer immediately when a refresh is already running',
        () async {
          final page1Completer = Completer<BreedsPage>();
          when(() => repository.fetchBreedsPage(page: 1))
              .thenAnswer((_) => page1Completer.future);

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

          await secondRefresh.future.timeout(const Duration(seconds: 1));
          expect(firstRefresh.isCompleted, isFalse);
          expect(secondRefresh.isCompleted, isTrue);

          page1Completer.complete(
            const BreedsPage(
              currentPage: 1,
              lastPage: 2,
              total: 40,
              items: [breed1, breed2],
            ),
          );
          await firstRefresh.future.timeout(const Duration(seconds: 1));

          verify(() => repository.fetchBreedsPage(page: 1)).called(1);
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
            () => repository.fetchBreedsPage(page: any(named: 'page')),
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
          when(() => repository.fetchBreedsPage(page: 1)).thenAnswer(
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
          when(() => repository.fetchBreedsPage(page: 1)).thenAnswer(
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

    group('Race condition prevention', () {
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
          when(() => repository.fetchBreedsPage(page: 1))
              .thenAnswer((_) => swrCompleter.future);
          when(() => repository.fetchBreedsPage(page: 2)).thenAnswer(
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
          when(() => repository.fetchBreedsPage(page: 3))
              .thenAnswer((_) => page3Completer.future);
          when(() => repository.fetchBreedsPage(page: 1)).thenAnswer(
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
          when(() => repository.fetchBreedsPage(page: 1))
              .thenThrow(Exception('SharedPreferences write failed'));
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
          when(() => repository.fetchBreedsPage(page: 2))
              .thenThrow(StateError('unexpected pagination error'));
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
        when(() => repository.fetchRandomFact())
            .thenThrow(const NetworkFailure());
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
        when(() => repository.findBreedByName(breed3.breed))
            .thenAnswer((_) async => breed3);
        when(() => repository.fetchRandomFact())
            .thenAnswer((_) async => sampleFact);
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
        verify(() => repository.findBreedByName(breed3.breed)).called(1);
        verify(() => repository.fetchRandomFact()).called(1);
      },
    );

    blocTest<BreedDetailCubit, BreedDetailState>(
      'emits failure state on cold start when findBreedByName throws AppFailure',
      setUp: () {
        when(() => repository.findBreedByName('UnknownBreed')).thenThrow(
          const NotFoundFailure(message: 'Raza no encontrada.'),
        );
        when(() => repository.fetchRandomFact())
            .thenAnswer((_) async => sampleFact);
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
        when(() => repository.findBreedByName(breed1.breed))
            .thenThrow(StateError('unexpected lookup failure'));
        when(() => repository.fetchRandomFact())
            .thenThrow(const FormatException('corrupt fact payload'));
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
        when(() => repository.findBreedByName(breed3.breed))
            .thenAnswer((_) async {
          calls++;
          if (calls == 1) {
            throw const NetworkFailure();
          }
          return breed3;
        });
        when(() => repository.fetchRandomFact())
            .thenAnswer((_) async => sampleFact);
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
        verify(() => repository.findBreedByName(breed3.breed)).called(2);
      },
    );
  });
}
