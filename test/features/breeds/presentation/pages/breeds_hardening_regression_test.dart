import 'dart:async';

import 'package:cat_directory_app/app.dart';
import 'package:cat_directory_app/core/errors/app_failure.dart';
import 'package:cat_directory_app/core/network/connectivity_monitor.dart';
import 'package:cat_directory_app/core/router/app_router.dart';
import 'package:cat_directory_app/features/breeds/domain/entities/breed.dart';
import 'package:cat_directory_app/features/breeds/domain/entities/breeds_page.dart';
import 'package:cat_directory_app/features/breeds/domain/entities/cached_breeds_result.dart';
import 'package:cat_directory_app/features/breeds/domain/entities/cat_fact.dart';
import 'package:cat_directory_app/features/breeds/domain/repositories/breeds_repository.dart';
import 'package:cat_directory_app/features/breeds/presentation/bloc/breed_detail_cubit.dart';
import 'package:cat_directory_app/features/breeds/presentation/bloc/breeds_bloc.dart';
import 'package:cat_directory_app/features/breeds/presentation/bloc/breeds_state.dart';
import 'package:cat_directory_app/features/breeds/presentation/pages/breed_detail_page.dart';
import 'package:cat_directory_app/features/breeds/presentation/pages/breeds_list_page.dart';
import 'package:cat_directory_app/features/breeds/presentation/widgets/shimmer_box.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockBreedsRepository extends Mock implements BreedsRepository {}

class _MockConnectivityMonitor extends Mock implements ConnectivityMonitor {}

List<Breed> _generateBreeds(int count, {String prefix = 'Breed'}) {
  return List<Breed>.generate(
    count,
    (index) => Breed(
      breed: '$prefix ${index.toString().padLeft(2, '0')}',
      country: 'Country $index',
      origin: 'Natural',
      coat: 'Short',
      pattern: 'Solid',
    ),
  );
}

void main() {
  group('Issue #13 UI hardening flows (BreedsListPage & BreedDetailPage)', () {
    late _MockBreedsRepository repository;
    late _MockConnectivityMonitor connectivity;
    late StreamController<bool> connectivityStream;
    late BreedsBloc bloc;

    setUp(() {
      repository = _MockBreedsRepository();
      connectivity = _MockConnectivityMonitor();
      connectivityStream = StreamController<bool>.broadcast();

      when(() => connectivity.hasConnection).thenAnswer((_) async => true);
      when(() => connectivity.onStatusChanged)
          .thenAnswer((_) => connectivityStream.stream);
      when(() => repository.getCachedFirstPage()).thenReturn(null);

      bloc = BreedsBloc(
        repository: repository,
        connectivityMonitor: connectivity,
      );
    });

    tearDown(() async {
      await bloc.close();
      await connectivityStream.close();
    });

    testWidgets(
      '(1) cold start offline with cache renders breeds immediately with 0 skeleton flash',
      (tester) async {
        final hasConnectionCompleter = Completer<bool>();
        addTearDown(() {
          if (!hasConnectionCompleter.isCompleted) {
            hasConnectionCompleter.complete(false);
          }
        });
        when(() => connectivity.hasConnection)
            .thenAnswer((_) => hasConnectionCompleter.future);

        const cachedBreeds = [
          Breed(
            breed: 'Abyssinian',
            country: 'Ethiopia',
            origin: 'Natural/Standard',
            coat: 'Short',
            pattern: 'Ticked',
          ),
          Breed(
            breed: 'Bengal',
            country: 'United States',
            origin: 'Hybrid',
            coat: 'Short',
            pattern: 'Spotted',
          ),
        ];

        when(() => repository.getCachedFirstPage()).thenReturn(
          CachedBreedsResult(
            page: const BreedsPage(
              currentPage: 1,
              lastPage: 2,
              total: 40,
              items: cachedBreeds,
            ),
            cachedAt: DateTime.now().toUtc().subtract(const Duration(minutes: 2)),
            isExpired: false,
          ),
        );

        final observedStatuses = <BreedsStatus>[];
        final statusSub = bloc.stream.listen((s) => observedStatuses.add(s.status));
        addTearDown(statusSub.cancel);

        final router = createAppRouter(
          detailCubitFactory: () => BreedDetailCubit(repository: repository),
        );
        addTearDown(router.dispose);

        final loadedFromCache = bloc.stream.firstWhere(
          (s) => s.status == BreedsStatus.loaded,
        );
        await tester.pumpWidget(CatDirectoryApp(breedsBloc: bloc, router: router));
        await tester.runAsync(() => loadedFromCache);
        await tester.pump();

        expect(hasConnectionCompleter.isCompleted, isFalse);
        expect(find.byType(BreedsSkeletonList), findsNothing);
        expect(find.text('Abyssinian'), findsOneWidget);
        expect(find.text('Bengal'), findsOneWidget);
        expect(observedStatuses, isNot(contains(BreedsStatus.loading)));

        // Resolve connectivity offline and verify offline banner appears without remote fetch.
        final wentOffline = bloc.stream.firstWhere((s) => !s.isOnline);
        hasConnectionCompleter.complete(false);
        await tester.runAsync(() => wentOffline);
        await tester.pump();

        expect(bloc.state.isOnline, isFalse);
        expect(bloc.state.isFromCache, isTrue);
        expect(find.byType(BreedsSkeletonList), findsNothing);
        expect(find.text('Abyssinian'), findsOneWidget);
        expect(
          find.textContaining('Sin conexión · Datos guardados'),
          findsOneWidget,
        );
        verifyNever(
          () => repository.fetchBreedsPage(
            page: any(named: 'page'),
            cancelToken: any(named: 'cancelToken'),
          ),
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );

    testWidgets(
      '(2) pull-to-refresh cancels in-flight page 2 and subsequent scroll loads page 2 cleanly',
      (tester) async {
        final initialPage1 = _generateBreeds(20);
        final refreshedPage1 = [
          const Breed(
            breed: 'Siamese',
            country: 'Thailand',
            origin: 'Natural',
            coat: 'Short',
            pattern: 'Colorpoint',
          ),
          ...initialPage1.skip(1),
        ];
        final page2Breeds = _generateBreeds(10, prefix: 'Page2');

        var page1Calls = 0;
        when(
          () => repository.fetchBreedsPage(
            page: 1,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async {
          page1Calls++;
          return BreedsPage(
            currentPage: 1,
            lastPage: 2,
            total: 30,
            items: page1Calls == 1 ? initialPage1 : refreshedPage1,
          );
        });

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
            BreedsPage(
              currentPage: 2,
              lastPage: 2,
              total: 30,
              items: page2Breeds,
            ),
          );
        });

        final router = createAppRouter(
          detailCubitFactory: () => BreedDetailCubit(repository: repository),
        );
        addTearDown(router.dispose);

        final loadedPage1 = bloc.stream.firstWhere(
          (s) => s.status == BreedsStatus.loaded && s.breeds.length == 20,
        );
        await tester.pumpWidget(CatDirectoryApp(breedsBloc: bloc, router: router));
        await tester.runAsync(() => loadedPage1);
        await tester.pumpAndSettle();

        // Scroll to bottom to trigger page 2 request (which stays in-flight).
        final scrollable = find.byType(CustomScrollView);
        for (var i = 0; i < 8 && !bloc.state.isLoadingMore; i++) {
          await tester.drag(scrollable, const Offset(0, -1200));
          await tester.pump();
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
        }
        await tester.pump();

        expect(bloc.state.isLoadingMore, isTrue);
        expect(page2Calls, 1);
        expect(page2Tokens.first?.isCancelled, isFalse);

        // Scroll back to top and trigger Pull-to-Refresh while page 2 is still in-flight.
        for (var i = 0; i < 8; i++) {
          await tester.drag(scrollable, const Offset(0, 1200));
          await tester.pump();
        }
        final refreshed = bloc.stream.firstWhere(
          (s) => s.breeds.isNotEmpty && s.breeds.first.breed == 'Siamese',
        );
        await tester.fling(scrollable, const Offset(0, 350), 1000);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.runAsync(() => refreshed.timeout(const Duration(seconds: 3)));
        await tester.pumpAndSettle();

        expect(page2Tokens.first?.isCancelled, isTrue);
        expect(find.text('Siamese'), findsOneWidget);
        expect(find.textContaining('cancelada'), findsNothing);
        expect(bloc.state.currentPage, 1);
        expect(bloc.state.isLoadingMore, isFalse);

        // Scroll to bottom again; second page 2 fetch must NOT be dropped by droppable().
        final loadedPage2 = bloc.stream.firstWhere(
          (s) => s.currentPage == 2 && !s.isLoadingMore,
        );
        for (var i = 0; i < 10 && bloc.state.currentPage < 2; i++) {
          await tester.drag(scrollable, const Offset(0, -1200));
          await tester.pump();
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await tester.pump();
        }
        await tester.runAsync(() => loadedPage2.timeout(const Duration(seconds: 3)));
        await tester.pumpAndSettle();

        expect(page2Calls, 2);
        expect(bloc.state.currentPage, 2);
        expect(bloc.state.breeds.length, 30);

        // Scroll through the newly appended page 2 items to verify the end-of-list footer.
        await tester.scrollUntilVisible(
          find.text('Fin del directorio · 30 razas exploradas'),
          300,
          scrollable: find.descendant(
            of: scrollable,
            matching: find.byType(Scrollable),
          ),
        );
        expect(find.text('Page2 09'), findsOneWidget);
        expect(
          find.text('Fin del directorio · 30 razas exploradas'),
          findsOneWidget,
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );

    testWidgets(
      '(3) offline without cached data shows accurate messaging without "datos guardados"',
      (tester) async {
        when(() => connectivity.hasConnection).thenAnswer((_) async => false);

        final router = createAppRouter(
          detailCubitFactory: () => BreedDetailCubit(repository: repository),
        );
        addTearDown(router.dispose);

        final reachedFailure = bloc.stream.firstWhere(
          (s) => s.status == BreedsStatus.failure && !s.isOnline,
        );
        await tester.pumpWidget(CatDirectoryApp(breedsBloc: bloc, router: router));
        await tester.runAsync(() => reachedFailure);
        await tester.pumpAndSettle();

        // Also simulate connectivity stream emitting false on cold start.
        connectivityStream.add(false);
        await tester.pump();

        expect(find.text('Estás sin conexión a internet'), findsOneWidget);
        expect(find.text(const NetworkFailure().message), findsOneWidget);

        void expectNoSavedDataCopy() {
          final allTextWidgets = tester.widgetList<Text>(find.byType(Text));
          for (final textWidget in allTextWidgets) {
            final value = (textWidget.data ?? '').toLowerCase();
            expect(
              value,
              isNot(contains('datos guardados')),
              reason: 'Offline empty state must not mention saved data: "$value"',
            );
            expect(
              value,
              isNot(contains('datos cargados')),
              reason: 'Offline empty state must not mention loaded data: "$value"',
            );
          }
        }

        expectNoSavedDataCopy();

        // Tap "Reintentar" inside ConnectivityStatusBanner (triggers BreedsRefreshed).
        final noticeReceived = bloc.stream.firstWhere((s) => s.notice != null);
        await tester.tap(find.text('Reintentar').first);
        await tester.runAsync(() => noticeReceived);
        await tester.pump();

        expect(find.text(const NetworkFailure().message), findsAtLeastNWidgets(1));
        expectNoSavedDataCopy();

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );

    testWidgets(
      '(4) rapid pop of BreedDetailPage cancels in-flight /fact without errors',
      (tester) async {
        final errors = <String>[];
        final previousOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          errors.add(details.exceptionAsString());
        };
        addTearDown(() => FlutterError.onError = previousOnError);

        const abyssinian = Breed(
          breed: 'Abyssinian',
          country: 'Ethiopia',
          origin: 'Natural/Standard',
          coat: 'Short',
          pattern: 'Ticked',
        );

        final factCompleter = Completer<CatFact>();
        CancelToken? capturedFactToken;

        when(
          () => repository.fetchBreedsPage(
            page: 1,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer(
          (_) async => const BreedsPage(
            currentPage: 1,
            lastPage: 1,
            total: 1,
            items: [abyssinian],
          ),
        );
        when(
          () => repository.fetchRandomFact(
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((invocation) {
          capturedFactToken =
              invocation.namedArguments[#cancelToken] as CancelToken?;
          return factCompleter.future;
        });

        final router = createAppRouter(
          detailCubitFactory: () => BreedDetailCubit(repository: repository),
        );
        addTearDown(router.dispose);

        final loaded = bloc.stream.firstWhere(
          (s) => s.status == BreedsStatus.loaded,
        );
        await tester.pumpWidget(CatDirectoryApp(breedsBloc: bloc, router: router));
        await tester.runAsync(() => loaded);
        await tester.pumpAndSettle();

        // Navigate to detail screen while /fact remains pending.
        await tester.tap(find.text('Abyssinian'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));

        expect(find.byType(BreedDetailPage), findsOneWidget);
        expect(capturedFactToken, isNotNull);
        expect(capturedFactToken!.isCancelled, isFalse);

        // Immediately pop back before /fact finishes.
        await tester.tap(find.byTooltip('Volver al directorio'));
        await tester.pumpAndSettle();

        expect(find.byType(BreedDetailPage), findsNothing);
        expect(find.byType(BreedsListPage), findsOneWidget);
        expect(capturedFactToken!.isCancelled, isTrue);

        // Even if the underlying mock completes later, no StateError/FlutterError occurs.
        factCompleter.complete(
          const CatFact(fact: 'Late fact after pop', length: 19),
        );
        await tester.pump();

        expect(errors, isEmpty, reason: errors.join('\n'));
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  });
}
