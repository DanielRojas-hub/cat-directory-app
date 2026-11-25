import 'dart:async';

import 'package:cat_directory_app/core/errors/app_failure.dart';
import 'package:cat_directory_app/core/network/connectivity_monitor.dart';
import 'package:cat_directory_app/core/storage/cache_envelope.dart';
import 'package:cat_directory_app/features/breeds/data/datasources/breeds_local_datasource.dart';
import 'package:cat_directory_app/features/breeds/data/datasources/breeds_remote_datasource.dart';
import 'package:cat_directory_app/features/breeds/data/models/breed_model.dart';
import 'package:cat_directory_app/features/breeds/data/models/breeds_page_model.dart';
import 'package:cat_directory_app/features/breeds/data/repositories/breeds_repository_impl.dart';
import 'package:cat_directory_app/features/breeds/domain/entities/breed.dart';
import 'package:cat_directory_app/features/breeds/domain/entities/breeds_page.dart';
import 'package:cat_directory_app/features/breeds/domain/repositories/breeds_repository.dart';
import 'package:cat_directory_app/features/breeds/presentation/bloc/breeds_bloc.dart';
import 'package:cat_directory_app/features/breeds/presentation/bloc/breeds_event.dart';
import 'package:cat_directory_app/features/breeds/presentation/bloc/breeds_state.dart';
import 'package:cat_directory_app/features/breeds/presentation/pages/breeds_list_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockBreedsRepository extends Mock implements BreedsRepository {}

class _MockRemoteDataSource extends Mock implements BreedsRemoteDataSource {}

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

Widget _buildPage(BreedsBloc bloc) {
  return BlocProvider<BreedsBloc>.value(
    value: bloc,
    child: const MaterialApp(
      home: BreedsListPage(),
    ),
  );
}

void main() {
  group('BreedsListPage UI regression flows (Issue #2)', () {
    late _MockBreedsRepository repository;
    late _MockConnectivityMonitor connectivity;
    late List<BreedsBloc> createdBlocs;

    Future<BreedsBloc> createStartedBloc(
      WidgetTester tester, {
      BreedsRepository? customRepository,
      Duration searchDebounceDuration = const Duration(milliseconds: 30),
    }) async {
      late BreedsBloc bloc;
      await tester.runAsync(() async {
        bloc = BreedsBloc(
          repository: customRepository ?? repository,
          connectivityMonitor: connectivity,
          searchDebounceDuration: searchDebounceDuration,
        );
        createdBlocs.add(bloc);
        final reachedLoaded = bloc.stream.firstWhere(
          (s) => s.status == BreedsStatus.loaded,
        );
        bloc.add(const BreedsStarted());
        await reachedLoaded;
      });
      return bloc;
    }

    setUp(() {
      repository = _MockBreedsRepository();
      connectivity = _MockConnectivityMonitor();
      createdBlocs = <BreedsBloc>[];

      when(() => connectivity.hasConnection).thenAnswer((_) async => true);
      when(() => connectivity.onStatusChanged)
          .thenAnswer((_) => const Stream<bool>.empty());
      when(() => repository.getCachedFirstPage()).thenReturn(null);
    });

    tearDown(() async {
      for (final bloc in createdBlocs) {
        await bloc.close();
      }
      createdBlocs.clear();
    });

    testWidgets(
      'Pull-to-Refresh closes RefreshIndicator cleanly on success and offline',
      (tester) async {
        final initialBreeds = _generateBreeds(12);
        final refreshedBreeds = [
          const Breed(
            breed: 'Siamese',
            country: 'Thailand',
            origin: 'Natural',
            coat: 'Short',
            pattern: 'Colorpoint',
          ),
          ...initialBreeds.skip(1),
        ];

        var callCount = 0;
        final refreshCompleter = Completer<BreedsPage>();
        addTearDown(() {
          if (!refreshCompleter.isCompleted) {
            refreshCompleter.complete(
              BreedsPage(
                currentPage: 1,
                lastPage: 2,
                total: 24,
                items: initialBreeds,
              ),
            );
          }
        });

        when(() => repository.fetchBreedsPage(page: 1)).thenAnswer((_) {
          callCount++;
          if (callCount == 1) {
            return Future<BreedsPage>.value(
              BreedsPage(
                currentPage: 1,
                lastPage: 2,
                total: 24,
                items: initialBreeds,
              ),
            );
          }
          return refreshCompleter.future;
        });

        final bloc = await createStartedBloc(tester);

        await tester.pumpWidget(_buildPage(bloc));
        await tester.pumpAndSettle();

        expect(find.text('Breed 00'), findsOneWidget);

        // Trigger Pull-to-Refresh gesture while remote fetch is pending.
        await tester.fling(
          find.byType(CustomScrollView),
          const Offset(0, 350),
          1000,
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.runAsync(() async {
          if (!bloc.state.isRevalidating) {
            await bloc.stream.firstWhere((s) => s.isRevalidating);
          }
        });
        await tester.pump();

        expect(callCount, 2);
        expect(bloc.state.isRevalidating, isTrue);

        // Complete refresh and verify RefreshIndicator closes cleanly.
        await tester.runAsync(() async {
          final settled = bloc.stream.firstWhere((s) => !s.isRevalidating);
          refreshCompleter.complete(
            BreedsPage(
              currentPage: 1,
              lastPage: 2,
              total: 24,
              items: refreshedBreeds,
            ),
          );
          await settled;
        });
        await tester.pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 5),
        );

        expect(bloc.state.isRevalidating, isFalse);
        expect(find.text('Siamese'), findsOneWidget);
        verifyNever(() => repository.invalidateCache());

        // Trigger Pull-to-Refresh while offline and verify indicator closes cleanly.
        when(() => connectivity.hasConnection).thenAnswer((_) async => false);
        await tester.fling(
          find.byType(CustomScrollView),
          const Offset(0, 350),
          1000,
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.runAsync(() async {
          if (bloc.state.isOnline) {
            await bloc.stream.firstWhere((s) => !s.isOnline);
          }
        });
        await tester.pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 5),
        );

        expect(bloc.state.isOnline, isFalse);
        expect(find.text('Siamese'), findsOneWidget);
        expect(
          find.text('Sin conexión a internet. Mostrando los datos guardados.'),
          findsOneWidget,
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );

    testWidgets(
      'local search filters without triggering remote pagination on scroll',
      (tester) async {
        final page1Breeds = _generateBreeds(15);
        when(() => repository.fetchBreedsPage(page: 1)).thenAnswer(
          (_) async => BreedsPage(
            currentPage: 1,
            lastPage: 3,
            total: 45,
            items: page1Breeds,
          ),
        );

        final bloc = await createStartedBloc(tester);

        await tester.pumpWidget(_buildPage(bloc));
        await tester.pumpAndSettle();

        // Filter down to a single item while hasMore == true.
        await tester.enterText(find.byType(TextField), 'Breed 01');
        await tester.runAsync(() async {
          await bloc.stream.firstWhere((s) => s.searchQuery == 'Breed 01');
        });
        await tester.pumpAndSettle();

        expect(bloc.state.isSearching, isTrue);
        expect(
          find.descendant(
            of: find.byType(CustomScrollView),
            matching: find.text('Breed 01'),
          ),
          findsOneWidget,
        );
        expect(find.text('Breed 00'), findsNothing);
        expect(find.text('Cargar más razas'), findsOneWidget);

        // Scrolling during active local search must NOT trigger page 2 fetch.
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
        await tester.pumpAndSettle();

        verifyNever(() => repository.fetchBreedsPage(page: 2));

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );

    testWidgets(
      'intermediate pagination error prevents auto-scroll retry loop until manual retry',
      (tester) async {
        final page1Breeds = _generateBreeds(15);
        final page2Breeds = _generateBreeds(5, prefix: 'Page2');

        when(() => repository.fetchBreedsPage(page: 1)).thenAnswer(
          (_) async => BreedsPage(
            currentPage: 1,
            lastPage: 3,
            total: 45,
            items: page1Breeds,
          ),
        );

        var page2Calls = 0;
        var shouldFailPage2 = true;
        when(() => repository.fetchBreedsPage(page: 2)).thenAnswer((_) async {
          page2Calls++;
          if (shouldFailPage2) {
            throw const NetworkFailure();
          }
          return BreedsPage(
            currentPage: 2,
            lastPage: 3,
            total: 45,
            items: page2Breeds,
          );
        });

        final bloc = await createStartedBloc(tester);

        await tester.pumpWidget(_buildPage(bloc));
        await tester.pumpAndSettle();

        // Scroll to bottom until pagination error footer is built and visible.
        final scrollable = find.descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        );
        final errorReached = bloc.stream
            .firstWhere((s) => s.paginationErrorMessage != null)
            .timeout(const Duration(seconds: 5));

        for (var i = 0; i < 6 && bloc.state.paginationErrorMessage == null; i++) {
          await tester.drag(scrollable, const Offset(0, -500));
          await tester.pump();
        }
        await tester.runAsync(() => errorReached);
        await tester.pumpAndSettle();

        // Scroll further to ensure PaginationFooter is visible in the viewport.
        await tester.scrollUntilVisible(
          find.text('Reintentar página'),
          300,
          scrollable: scrollable,
        );
        await tester.pumpAndSettle();

        expect(page2Calls, 1);
        expect(bloc.state.breeds.length, 15);
        expect(
          find.text('No se pudo cargar la siguiente página'),
          findsOneWidget,
        );
        expect(find.text('Reintentar página'), findsOneWidget);

        // Additional downward drags at the bottom must NOT trigger an auto-retry loop.
        await tester.drag(scrollable, const Offset(0, -300));
        await tester.pumpAndSettle();
        await tester.drag(scrollable, const Offset(0, -300));
        await tester.pumpAndSettle();

        expect(page2Calls, 1);

        // Wait for error SnackBar (3s) to dismiss so the footer button is unobstructed.
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();

        // Tapping manual retry succeeds and appends page 2.
        shouldFailPage2 = false;
        final page2Loaded = bloc.stream.firstWhere((s) => s.currentPage == 2);
        await tester.tap(find.text('Reintentar página'));
        await tester.runAsync(
          () => page2Loaded.timeout(const Duration(seconds: 5)),
        );
        await tester.pumpAndSettle();

        expect(page2Calls, 2);
        expect(bloc.state.currentPage, 2);
        expect(bloc.state.breeds.length, 20);
        expect(bloc.state.paginationErrorMessage, isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );

    testWidgets(
      'offline-first persisted cache survives failed Pull-to-Refresh across app restart',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final remoteDataSource = _MockRemoteDataSource();
        final localDataSource = BreedsLocalDataSourceImpl(
          SharedPreferencesCacheStore(prefs),
        );
        final realRepository = BreedsRepositoryImpl(
          remoteDataSource: remoteDataSource,
          localDataSource: localDataSource,
        );

        const page1Model = BreedsPageModel(
          currentPage: 1,
          lastPage: 2,
          total: 2,
          data: [
            BreedModel(
              breed: 'Abyssinian',
              country: 'Ethiopia',
              origin: 'Natural/Standard',
              coat: 'Short',
              pattern: 'Ticked',
            ),
            BreedModel(
              breed: 'Aegean',
              country: 'Greece',
              origin: 'Natural/Standard',
              coat: 'Semi-long',
              pattern: 'Bi- or tri-colored',
            ),
          ],
        );

        var failRefresh = false;
        when(
          () => remoteDataSource.fetchBreedsPage(page: 1, limit: 20),
        ).thenAnswer((_) async {
          if (failRefresh) {
            throw const NetworkFailure();
          }
          return page1Model;
        });

        final blocOnline = await createStartedBloc(
          tester,
          customRepository: realRepository,
        );

        await tester.pumpWidget(_buildPage(blocOnline));
        await tester.pumpAndSettle();

        expect(find.text('Abyssinian'), findsOneWidget);
        expect(realRepository.getCachedFirstPage(), isNotNull);

        // Simulate network error during Pull-to-Refresh.
        failRefresh = true;
        final refreshFailed = blocOnline.stream
            .firstWhere(
              (s) => !s.isRevalidating && s.notice?.kind == BreedsNoticeKind.error,
            )
            .timeout(const Duration(seconds: 5));
        await tester.fling(
          find.byType(CustomScrollView),
          const Offset(0, 350),
          1000,
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.runAsync(() => refreshFailed);
        await tester.pumpAndSettle();

        expect(find.text('Abyssinian'), findsOneWidget);
        expect(find.textContaining('No se pudo actualizar:'), findsOneWidget);
        expect(realRepository.getCachedFirstPage(), isNotNull);

        // Unmount app before simulating cold restart while offline.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();

        // Simulate reopening the app while offline.
        when(() => connectivity.hasConnection).thenAnswer((_) async => false);
        final blocOffline = await createStartedBloc(
          tester,
          customRepository: realRepository,
        );

        await tester.pumpWidget(_buildPage(blocOffline));
        await tester.pumpAndSettle();

        expect(find.text('Abyssinian'), findsOneWidget);
        expect(find.text('Aegean'), findsOneWidget);
        expect(
          find.textContaining('Sin conexión · Datos guardados'),
          findsOneWidget,
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  });
}
