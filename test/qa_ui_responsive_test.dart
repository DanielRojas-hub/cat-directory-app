import 'dart:async';

import 'package:cat_directory_app/app.dart';
import 'package:cat_directory_app/core/errors/app_failure.dart';
import 'package:cat_directory_app/core/network/connectivity_monitor.dart';
import 'package:cat_directory_app/core/router/app_router.dart';
import 'package:cat_directory_app/core/theme/app_theme.dart';
import 'package:cat_directory_app/features/breeds/domain/entities/breed.dart';
import 'package:cat_directory_app/features/breeds/domain/entities/breeds_page.dart';
import 'package:cat_directory_app/features/breeds/domain/entities/cat_fact.dart';
import 'package:cat_directory_app/features/breeds/domain/repositories/breeds_repository.dart';
import 'package:cat_directory_app/features/breeds/presentation/bloc/breed_detail_cubit.dart';
import 'package:cat_directory_app/features/breeds/presentation/bloc/breed_detail_state.dart';
import 'package:cat_directory_app/features/breeds/presentation/bloc/breeds_bloc.dart';
import 'package:cat_directory_app/features/breeds/presentation/bloc/breeds_state.dart';
import 'package:cat_directory_app/features/breeds/presentation/pages/breed_detail_page.dart';
import 'package:cat_directory_app/features/breeds/presentation/pages/breeds_list_page.dart';
import 'package:cat_directory_app/features/breeds/presentation/widgets/breed_card.dart';
import 'package:cat_directory_app/features/breeds/presentation/widgets/cat_fact_card.dart';
import 'package:cat_directory_app/features/breeds/presentation/widgets/connectivity_status_banner.dart';
import 'package:cat_directory_app/features/breeds/presentation/widgets/pagination_footer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockBreedsRepository extends Mock implements BreedsRepository {}

class _MockConnectivityMonitor extends Mock implements ConnectivityMonitor {}

const _abyssinian = Breed(
  breed: 'Abyssinian',
  country: 'Ethiopia',
  origin: 'Natural/Standard',
  coat: 'Short',
  pattern: 'Ticked',
);

const _bengal = Breed(
  breed: 'Bengal',
  country: 'United States',
  origin: 'Hybrid',
  coat: 'Short',
  pattern: 'Spotted',
);

const _longBreed = Breed(
  breed: 'American Wirehair Shorthair Extra Long Name',
  country: 'United Kingdom / United States of America',
  origin: 'Natural/Mutation',
  coat: 'Semi-long',
  pattern: 'Bi- or tri-colored',
);

Future<void> _guardNoFlutterErrors(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  final errors = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    errors.add(details.exceptionAsString());
  };
  try {
    await body();
  } finally {
    FlutterError.onError = previous;
  }
  expect(
    errors,
    isEmpty,
    reason: errors.join('\n---\n'),
  );
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  late _MockBreedsRepository repository;
  late _MockConnectivityMonitor connectivity;
  late BreedsBloc bloc;

  setUp(() {
    repository = _MockBreedsRepository();
    connectivity = _MockConnectivityMonitor();
    when(() => connectivity.hasConnection).thenAnswer((_) async => true);
    when(() => connectivity.onStatusChanged)
        .thenAnswer((_) => const Stream<bool>.empty());
    when(() => repository.getCachedFirstPage()).thenReturn(null);
    when(() => repository.invalidateCache()).thenAnswer((_) async {});
    when(
      () => repository.fetchBreedsPage(
        page: any(named: 'page'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((invocation) async {
      final page = invocation.namedArguments[#page] as int;
      return BreedsPage(
        currentPage: page >= 2 ? 2 : 1,
        lastPage: 2,
        total: 40,
        items: const [_abyssinian, _bengal, _longBreed],
      );
    });
    when(
      () => repository.findBreedByName(
        any(),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((_) async => _abyssinian);
    when(
      () => repository.fetchRandomFact(cancelToken: any(named: 'cancelToken')),
    ).thenAnswer(
      (_) async => const CatFact(
        fact: 'Cats sleep 12-16 hours a day.',
        length: 29,
      ),
    );

    bloc = BreedsBloc(
      repository: repository,
      connectivityMonitor: connectivity,
    );
  });

  tearDown(() async {
    await bloc.close();
  });

  group('QA-1 / QA-9 / QA-12: Responsive layout stress (0 RenderFlex overflows)',
      () {
    testWidgets(
      '320px width + textScaler 2.0x renders AppBar, banners, BreedCard (maxLines 2) and PaginationFooter with 0 overflows',
      (tester) async {
        _setViewport(tester, const Size(320, 568));

        await _guardNoFlutterErrors(tester, () async {
          bloc.emit(
            BreedsState(
              status: BreedsStatus.loaded,
              breeds: const [_longBreed, _abyssinian],
              currentPage: 1,
              lastPage: 3,
              total: 98,
              isRevalidating: true,
              isLoadingMore: true,
              isOnline: true,
              lastSyncedAt: DateTime.now().toUtc(),
            ),
          );

          await tester.pumpWidget(
            BlocProvider<BreedsBloc>.value(
              value: bloc,
              child: MaterialApp(
                theme: AppTheme.light(),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(2.0),
                  ),
                  child: child!,
                ),
                home: const BreedsListPage(),
              ),
            ),
          );
          await tester.pump();

          expect(find.text('Cat Directory'), findsOneWidget);
          expect(
            find.text('Actualizando directorio en segundo plano...'),
            findsOneWidget,
          );

          // Verify BreedCard allows up to 2 lines for breed and country.
          final breedTexts = tester.widgetList<Text>(
            find.descendant(
              of: find.byType(BreedCard).first,
              matching: find.byType(Text),
            ),
          );
          final nameText = breedTexts.firstWhere(
            (t) => t.data == _longBreed.breed,
          );
          final countryText = breedTexts.firstWhere(
            (t) => t.data == _longBreed.displayCountry,
          );
          expect(nameText.maxLines, 2);
          expect(countryText.maxLines, 2);

          // Scroll down to reveal PaginationFooter at 320px + 2.0x textScaler.
          await tester.scrollUntilVisible(
            find.text('Cargando más razas...'),
            200,
            scrollable: find.descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            ),
          );
          expect(find.text('Cargando más razas...'), findsOneWidget);

          // Test PaginationFooter end-of-list & ConnectivityStatusBanner offline/cache at 320px + 1.5x.
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.5),
                ),
                child: child!,
              ),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      ConnectivityStatusBanner(
                        isOnline: false,
                        isFromCache: true,
                        isRevalidating: false,
                        lastSyncedAt: DateTime.now().toUtc(),
                        onRetry: () {},
                      ),
                      ConnectivityStatusBanner(
                        isOnline: true,
                        isFromCache: true,
                        isRevalidating: false,
                        lastSyncedAt: DateTime.now().toUtc(),
                        onRetry: () {},
                      ),
                      PaginationFooter(
                        isLoadingMore: true,
                        hasMore: true,
                        isSearching: false,
                        loadedCount: 20,
                        totalCount: 98,
                        errorMessage: null,
                        onRetry: () {},
                        onLoadMore: () {},
                      ),
                      PaginationFooter(
                        isLoadingMore: false,
                        hasMore: false,
                        isSearching: false,
                        loadedCount: 98,
                        totalCount: 98,
                        errorMessage: null,
                        onRetry: () {},
                        onLoadMore: () {},
                      ),
                      PaginationFooter(
                        isLoadingMore: false,
                        hasMore: true,
                        isSearching: false,
                        loadedCount: 20,
                        totalCount: 98,
                        errorMessage: 'Sin conexión a internet.',
                        onRetry: () {},
                        onLoadMore: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          expect(
            find.text('Fin del directorio · 98 razas exploradas'),
            findsOneWidget,
          );

          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        });
      },
    );

    testWidgets(
      'Landscape 844x390 with Notch padding + textScaler 1.5x has 0 overflows across error, empty, detail and 404 views',
      (tester) async {
        _setViewport(tester, const Size(844, 390));
        const notchMediaQuery = MediaQueryData(
          size: Size(844, 390),
          padding: EdgeInsets.only(left: 59, right: 59, bottom: 21),
          textScaler: TextScaler.linear(1.5),
        );

        await _guardNoFlutterErrors(tester, () async {
          // 1. _InitialErrorView in Landscape 844x390
          bloc.emit(
            const BreedsState(
              status: BreedsStatus.failure,
              isOnline: false,
              errorMessage: 'Sin conexión a internet. Verifica tu red.',
            ),
          );
          await tester.pumpWidget(
            BlocProvider<BreedsBloc>.value(
              value: bloc,
              child: MaterialApp(
                theme: AppTheme.light(),
                builder: (context, child) => MediaQuery(
                  data: notchMediaQuery,
                  child: child!,
                ),
                home: const BreedsListPage(),
              ),
            ),
          );
          await tester.pump();
          expect(find.text('Reintentar'), findsAtLeastNWidgets(1));
          expect(
            find.descendant(
              of: find.byType(BreedsListPage),
              matching: find.byWidgetPredicate(
                (w) => w is SafeArea && !w.top,
              ),
            ),
            findsOneWidget,
          );

          // 2. _EmptySearchView in Landscape 844x390 with open keyboard
          bloc.emit(
            const BreedsState(
              status: BreedsStatus.loaded,
              breeds: [_abyssinian],
              searchQuery: 'zzzz',
              currentPage: 1,
              lastPage: 2,
              total: 40,
              paginationErrorMessage: 'Tiempo de espera agotado.',
            ),
          );
          await tester.pumpWidget(
            BlocProvider<BreedsBloc>.value(
              value: bloc,
              child: MaterialApp(
                theme: AppTheme.light(),
                builder: (context, child) => MediaQuery(
                  data: notchMediaQuery.copyWith(
                    viewInsets: const EdgeInsets.only(bottom: 180),
                  ),
                  child: child!,
                ),
                home: const BreedsListPage(),
              ),
            ),
          );
          await tester.pump();
          expect(find.text('Sin coincidencias para "zzzz"'), findsOneWidget);
          expect(find.text('Tiempo de espera agotado.'), findsOneWidget);

          // 3. _EmptyDirectoryView (API 200 OK with data: []) in Landscape
          bloc.emit(
            const BreedsState(
              status: BreedsStatus.loaded,
              breeds: [],
              currentPage: 1,
              lastPage: 1,
              total: 0,
            ),
          );
          await tester.runAsync(() => Future<void>.delayed(Duration.zero));
          await tester.pump();
          expect(find.text('No hay razas disponibles'), findsOneWidget);

          // 4. BreedDetailPage lookup error view in Landscape
          when(
            () => repository.findBreedByName(
              any(),
              cancelToken: any(named: 'cancelToken'),
            ),
          ).thenThrow(const NotFoundFailure(message: 'No encontrada'));
          final detailRouter = createAppRouter(
            initialLocation: AppRoutes.breedDetailPath('UnknownCat'),
            detailCubitFactory: () => BreedDetailCubit(repository: repository),
          );
          addTearDown(detailRouter.dispose);

          await tester.pumpWidget(
            BlocProvider<BreedsBloc>.value(
              value: bloc,
              child: MaterialApp.router(
                theme: AppTheme.dark(),
                builder: (context, child) => MediaQuery(
                  data: notchMediaQuery,
                  child: child!,
                ),
                routerConfig: detailRouter,
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.text('No pudimos cargar "UnknownCat"'), findsOneWidget);

          // 5. _RouteNotFoundPage in Landscape
          final notFoundRouter = createAppRouter(
            initialLocation: '/invalid/deep/route',
            detailCubitFactory: () => BreedDetailCubit(repository: repository),
          );
          addTearDown(notFoundRouter.dispose);

          await tester.pumpWidget(
            BlocProvider<BreedsBloc>.value(
              value: bloc,
              child: MaterialApp.router(
                theme: AppTheme.dark(),
                builder: (context, child) => MediaQuery(
                  data: notchMediaQuery,
                  child: child!,
                ),
                routerConfig: notFoundRouter,
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.text('Volver al directorio'), findsOneWidget);

          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        });
      },
    );
  });

  group('QA-2 / QA-3 / QA-5 / QA-6 / QA-7: Search, empty states and keyboard',
      () {
    testWidgets(
      '_searchController stays synced with BreedsBloc.state.searchQuery on remount',
      (tester) async {
        final router = createAppRouter(
          detailCubitFactory: () => BreedDetailCubit(repository: repository),
        );
        addTearDown(router.dispose);

        final reachedLoaded = bloc.stream.firstWhere(
          (s) => s.status == BreedsStatus.loaded,
        );
        await tester.pumpWidget(
          CatDirectoryApp(breedsBloc: bloc, router: router),
        );
        await tester.runAsync(() => reachedLoaded);
        await tester.pumpAndSettle();

        final queryApplied = bloc.stream.firstWhere(
          (s) => s.searchQuery == 'Aby',
        );
        await tester.enterText(find.byType(TextField), 'Aby');
        await tester.runAsync(() => queryApplied);
        await tester.pumpAndSettle();
        expect(bloc.state.searchQuery, 'Aby');

        // Navigate with go() so BreedsListPage is unmounted, then return.
        router.go(AppRoutes.breedDetailPath('Abyssinian'));
        await tester.pumpAndSettle();

        router.go(AppRoutes.home);
        await tester.pumpAndSettle();

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.controller?.text, 'Aby');
        expect(find.byTooltip('Limpiar búsqueda'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );

    testWidgets(
      'tapping X clears search instantaneously without 300ms lag and prevents stale debounce',
      (tester) async {
        final router = createAppRouter(
          detailCubitFactory: () => BreedDetailCubit(repository: repository),
        );
        addTearDown(router.dispose);

        final reachedLoaded = bloc.stream.firstWhere(
          (s) => s.status == BreedsStatus.loaded,
        );
        await tester.pumpWidget(
          CatDirectoryApp(breedsBloc: bloc, router: router),
        );
        await tester.runAsync(() => reachedLoaded);
        await tester.pumpAndSettle();

        // Filter to Abyssinian first.
        final filtered = bloc.stream.firstWhere(
          (s) => s.searchQuery == 'Abyssinian',
        );
        await tester.enterText(find.byType(TextField), 'Abyssinian');
        await tester.runAsync(() => filtered);
        await tester.pumpAndSettle();
        expect(find.text('Bengal'), findsNothing);

        // Start a new debounced query, then tap X immediately before 300ms.
        await tester.enterText(find.byType(TextField), 'Bengal');
        await tester.pump(const Duration(milliseconds: 50));

        final cleared = bloc.stream.firstWhere((s) => s.searchQuery.isEmpty);
        final stopwatch = Stopwatch()..start();
        await tester.tap(find.byTooltip('Limpiar búsqueda'));
        await tester.runAsync(() => cleared);
        stopwatch.stop();
        await tester.pump();

        // Restored instantaneously without waiting for the 300ms debounce.
        expect(stopwatch.elapsedMilliseconds, lessThan(150));
        expect(bloc.state.searchQuery, isEmpty);
        expect(find.text('Abyssinian'), findsOneWidget);
        expect(find.text('Bengal'), findsOneWidget);

        // Advancing past 300ms in real time must not reapply the cancelled 'Bengal' query.
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 360)),
        );
        await tester.pump();
        expect(bloc.state.searchQuery, isEmpty);
        expect(find.text('Abyssinian'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );

    testWidgets(
      'displays _EmptyDirectoryView when API returns 200 OK with data: [] and reloads on tap',
      (tester) async {
        var calls = 0;
        when(
          () => repository.fetchBreedsPage(
            page: 1,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async {
          calls++;
          if (calls == 1) {
            return const BreedsPage(
              currentPage: 1,
              lastPage: 1,
              total: 0,
              items: [],
            );
          }
          return const BreedsPage(
            currentPage: 1,
            lastPage: 1,
            total: 1,
            items: [_abyssinian],
          );
        });

        final router = createAppRouter(
          detailCubitFactory: () => BreedDetailCubit(repository: repository),
        );
        addTearDown(router.dispose);

        final reachedEmptyLoaded = bloc.stream.firstWhere(
          (s) => s.status == BreedsStatus.loaded,
        );
        await tester.pumpWidget(
          CatDirectoryApp(breedsBloc: bloc, router: router),
        );
        await tester.runAsync(() => reachedEmptyLoaded);
        await tester.pumpAndSettle();

        expect(find.text('No hay razas disponibles'), findsOneWidget);
        expect(find.text('Recargar'), findsOneWidget);

        final reachedReloaded = bloc.stream.firstWhere(
          (s) => s.breeds.isNotEmpty && !s.isRevalidating,
        );
        await tester.tap(find.text('Recargar'));
        await tester.runAsync(() => reachedReloaded);
        await tester.pumpAndSettle();

        expect(find.text('Abyssinian'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );

    testWidgets(
      '_EmptySearchView exposes loading spinner and pagination error feedback',
      (tester) async {
        final gate = Completer<void>();
        when(
          () => repository.fetchBreedsPage(
            page: 2,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async {
          await gate.future;
          throw const NetworkFailure(message: 'Error de red temporal');
        });

        bloc.emit(
          const BreedsState(
            status: BreedsStatus.loaded,
            breeds: [_abyssinian],
            searchQuery: 'Sphynx',
            currentPage: 1,
            lastPage: 2,
            total: 40,
          ),
        );

        await tester.pumpWidget(
          BlocProvider<BreedsBloc>.value(
            value: bloc,
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const BreedsListPage(),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Cargar más razas'), findsOneWidget);
        final reachedLoadingMore = bloc.stream.firstWhere(
          (s) => s.isLoadingMore,
        );
        await tester.tap(find.text('Cargar más razas'));
        await tester.runAsync(() => reachedLoadingMore);
        await tester.pump();

        expect(find.text('Cargando más razas...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        final reachedError = bloc.stream.firstWhere(
          (s) => !s.isLoadingMore && s.paginationErrorMessage != null,
        );
        gate.complete();
        await tester.runAsync(() => reachedError);
        await tester.pumpAndSettle();

        expect(find.text('Error de red temporal'), findsOneWidget);
        expect(find.text('Reintentar cargar más'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );

    testWidgets(
      'CustomScrollView configures keyboardDismissBehavior.onDrag and handles open keyboard on empty search',
      (tester) async {
        _setViewport(tester, const Size(390, 844));

        await _guardNoFlutterErrors(tester, () async {
          bloc.emit(
            const BreedsState(
              status: BreedsStatus.loaded,
              breeds: [_abyssinian, _bengal],
              currentPage: 1,
              lastPage: 1,
              total: 2,
            ),
          );

          await tester.pumpWidget(
            BlocProvider<BreedsBloc>.value(
              value: bloc,
              child: MaterialApp(
                theme: AppTheme.light(),
                home: const BreedsListPage(),
              ),
            ),
          );
          await tester.pump();

          final scrollView = tester.widget<CustomScrollView>(
            find.byType(CustomScrollView),
          );
          expect(
            scrollView.keyboardDismissBehavior,
            ScrollViewKeyboardDismissBehavior.onDrag,
          );

          // Open keyboard inset while in _EmptySearchView
          bloc.emit(bloc.state.copyWith(searchQuery: 'NoMatch'));
          await tester.pumpWidget(
            BlocProvider<BreedsBloc>.value(
              value: bloc,
              child: MaterialApp(
                theme: AppTheme.light(),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    viewInsets: const EdgeInsets.only(bottom: 300),
                  ),
                  child: child!,
                ),
                home: const BreedsListPage(),
              ),
            ),
          );
          await tester.pump();
          expect(find.text('Sin coincidencias para "NoMatch"'), findsOneWidget);

          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        });
      },
    );
  });

  group('QA-4 / QA-8 / QA-10: BreedDetailPage PopScope, canonical title & CatFactCard',
      () {
    testWidgets(
      'PopScope redirects to home directory on system Back in cold Deep Link',
      (tester) async {
        final router = createAppRouter(
          initialLocation: AppRoutes.breedDetailPath('Abyssinian'),
          detailCubitFactory: () => BreedDetailCubit(repository: repository),
        );
        addTearDown(router.dispose);

        final reachedLoaded = bloc.stream.firstWhere(
          (s) => s.status == BreedsStatus.loaded,
        );
        await tester.pumpWidget(
          CatDirectoryApp(breedsBloc: bloc, router: router),
        );
        await tester.runAsync(() => reachedLoaded);
        await tester.pumpAndSettle();

        expect(find.text('Ficha de la Raza'), findsOneWidget);

        // Simulate Android physical Back button / gesture.
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(find.text('Cat Directory'), findsOneWidget);
        expect(router.routeInformationProvider.value.uri.path, AppRoutes.home);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );

    testWidgets(
      'AppBar updates from raw route slug (/breed/abyssinian) to canonical breed name (Abyssinian)',
      (tester) async {
        final breedCompleter = Completer<Breed>();
        when(
          () => repository.findBreedByName(
            'abyssinian',
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) => breedCompleter.future);

        final router = createAppRouter(
          initialLocation: '/breed/abyssinian',
          detailCubitFactory: () => BreedDetailCubit(repository: repository),
        );
        addTearDown(router.dispose);

        final reachedLoaded = bloc.stream.firstWhere(
          (s) => s.status == BreedsStatus.loaded,
        );
        await tester.pumpWidget(
          CatDirectoryApp(breedsBloc: bloc, router: router),
        );
        await tester.runAsync(() => reachedLoaded);
        await tester.pump();

        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text('abyssinian'),
          ),
          findsOneWidget,
        );

        breedCompleter.complete(_abyssinian);
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text('Abyssinian'),
          ),
          findsOneWidget,
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );

    testWidgets(
      'CatFactCard aligns AnimatedSwitcher topLeft and never renders empty quotes for blank fact',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark(),
            home: Scaffold(
              body: CatFactCard(
                status: CatFactStatus.loaded,
                fact: const CatFact(fact: '   ', length: 3),
                errorMessage: null,
                onRefresh: () {},
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('“”'), findsNothing);
        expect(find.text('“   ”'), findsNothing);
        expect(find.text('Reintentar dato curioso'), findsOneWidget);

        final switcher = tester.widget<AnimatedSwitcher>(
          find.byType(AnimatedSwitcher),
        );
        final builtStack = switcher.layoutBuilder(
          const SizedBox(),
          const <Widget>[],
        );
        expect(builtStack, isA<Stack>());
        expect((builtStack as Stack).alignment, Alignment.topLeft);
      },
    );
  });

  group(
      'Issue #14: L10n (es), double-tap guard, normalized search, post-frame scroll & copy',
      () {
    const perFoldBreed = Breed(
      breed: 'PerFoldæ(Experimental Breed - WCF)',
      country: 'Europe',
      origin: 'Crossbreed',
      coat: 'Long',
      pattern: 'All',
    );
    const foldexBreed = Breed(
      breed: 'Foldex[4]',
      country: 'Canada',
      origin: 'Crossbreed',
      coat: 'Short',
      pattern: 'All',
    );
    const donskoyBreed = Breed(
      breed: 'Donskoy, or Don Sphynx',
      country: 'Russia',
      origin: 'Natural',
      coat: 'Hairless',
      pattern: 'Solid',
    );
    const accentedBreed = Breed(
      breed: 'Égyptian Mau',
      country: 'Egypt',
      origin: 'Natural',
      coat: 'Short',
      pattern: 'Spotted',
    );
    const nfdBreed = Breed(
      breed: 'e\u0301clair Cat',
      country: 'France',
      origin: 'Natural',
      coat: 'Short',
      pattern: 'Solid',
    );

    testWidgets(
      'CatDirectoryApp configures Spanish Locale("es") and localized Material system strings (M5)',
      (tester) async {
        final router = createAppRouter(
          detailCubitFactory: () => BreedDetailCubit(repository: repository),
        );
        addTearDown(router.dispose);

        final reachedLoaded = bloc.stream.firstWhere(
          (s) => s.status == BreedsStatus.loaded,
        );
        await tester.pumpWidget(
          CatDirectoryApp(breedsBloc: bloc, router: router),
        );
        await tester.runAsync(() => reachedLoaded);
        await tester.pumpAndSettle();

        final scaffoldContext = tester.element(find.byType(Scaffold));
        expect(Localizations.localeOf(scaffoldContext), const Locale('es'));

        final materialL10n = MaterialLocalizations.of(scaffoldContext);
        expect(materialL10n.backButtonTooltip, 'Atrás');
        expect(
          materialL10n.refreshIndicatorSemanticLabel.toLowerCase(),
          isNot('refresh'),
        );

        final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
        expect(app.locale, const Locale('es'));
        expect(app.supportedLocales, contains(const Locale('es')));

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );

    testWidgets(
      'rapid double-tap on BreedCard opens only one BreedDetailPage and resets after pop (M9)',
      (tester) async {
        when(
          () => repository.fetchBreedsPage(
            page: any(named: 'page'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer(
          (_) async => const BreedsPage(
            currentPage: 1,
            lastPage: 1,
            total: 2,
            items: [_abyssinian, _bengal],
          ),
        );

        final router = createAppRouter(
          detailCubitFactory: () => BreedDetailCubit(repository: repository),
        );
        addTearDown(router.dispose);

        final reachedLoaded = bloc.stream.firstWhere(
          (s) => s.status == BreedsStatus.loaded,
        );
        await tester.pumpWidget(
          CatDirectoryApp(breedsBloc: bloc, router: router),
        );
        await tester.runAsync(() => reachedLoaded);
        await tester.pumpAndSettle();

        final firstCard = find.byType(BreedCard).first;
        final secondCard = find.byType(BreedCard).at(1);

        // Two rapid taps on the same card (and an extra rapid tap on another card).
        await tester.tap(firstCard);
        await tester.pump(const Duration(milliseconds: 20));
        await tester.tap(firstCard, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 20));
        await tester.tap(secondCard, warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(find.byType(BreedDetailPage), findsOneWidget);
        expect(find.text('Abyssinian'), findsAtLeastNWidgets(1));
        verify(
          () => repository.fetchRandomFact(
            cancelToken: any(named: 'cancelToken'),
          ),
        ).called(1);

        // A single back navigation must return straight to BreedsListPage.
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(find.byType(BreedDetailPage), findsNothing);
        expect(find.byType(BreedsListPage), findsOneWidget);
        expect(router.routeInformationProvider.value.uri.path, AppRoutes.home);

        // Guard must reset so a subsequent tap opens BreedDetailPage normally.
        await tester.tap(find.byType(BreedCard).at(1));
        await tester.pumpAndSettle();

        expect(find.byType(BreedDetailPage), findsOneWidget);
        expect(find.text('Bengal'), findsAtLeastNWidgets(1));
        verify(
          () => repository.fetchRandomFact(
            cancelToken: any(named: 'cancelToken'),
          ),
        ).called(1);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );

    test(
      'BreedsState.filteredBreeds normalizes diacritics and ligatures for real Catfact Ninja names (B12)',
      () {
        const baseState = BreedsState(
          status: BreedsStatus.loaded,
          breeds: [
            perFoldBreed,
            foldexBreed,
            donskoyBreed,
            accentedBreed,
            nfdBreed,
            _abyssinian,
          ],
          currentPage: 1,
          lastPage: 1,
          total: 6,
        );

        expect(
          baseState.copyWith(searchQuery: 'perfoldae').filteredBreeds,
          [perFoldBreed],
        );
        expect(
          baseState.copyWith(searchQuery: 'PerFoldæ').filteredBreeds,
          [perFoldBreed],
        );
        expect(
          baseState.copyWith(searchQuery: 'foldex').filteredBreeds,
          [foldexBreed],
        );
        expect(
          baseState.copyWith(searchQuery: 'Foldex[4]').filteredBreeds,
          [foldexBreed],
        );
        expect(
          baseState.copyWith(searchQuery: 'don sphynx').filteredBreeds,
          [donskoyBreed],
        );
        expect(
          baseState.copyWith(searchQuery: 'donskoy').filteredBreeds,
          [donskoyBreed],
        );
        expect(
          baseState.copyWith(searchQuery: 'egyptian').filteredBreeds,
          [accentedBreed],
        );
        expect(
          baseState.copyWith(searchQuery: 'eclair').filteredBreeds,
          [nfdBreed],
        );
      },
    );

    testWidgets(
      'UI search finds PerFoldæ with "perfoldae", Foldex[4] and Donskoy, or Don Sphynx (B12)',
      (tester) async {
        when(
          () => repository.fetchBreedsPage(
            page: any(named: 'page'),
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer(
          (_) async => const BreedsPage(
            currentPage: 1,
            lastPage: 1,
            total: 4,
            items: [perFoldBreed, foldexBreed, donskoyBreed, _abyssinian],
          ),
        );

        final router = createAppRouter(
          detailCubitFactory: () => BreedDetailCubit(repository: repository),
        );
        addTearDown(router.dispose);

        final reachedLoaded = bloc.stream.firstWhere(
          (s) => s.status == BreedsStatus.loaded,
        );
        await tester.pumpWidget(
          CatDirectoryApp(breedsBloc: bloc, router: router),
        );
        await tester.runAsync(() => reachedLoaded);
        await tester.pumpAndSettle();

        final queryPerFold = bloc.stream.firstWhere(
          (s) => s.searchQuery == 'perfoldae',
        );
        await tester.enterText(find.byType(TextField), 'perfoldae');
        await tester.runAsync(() => queryPerFold);
        await tester.pumpAndSettle();

        expect(
          find.text('PerFoldæ(Experimental Breed - WCF)'),
          findsOneWidget,
        );
        expect(find.text('Foldex[4]'), findsNothing);

        final queryFoldex = bloc.stream.firstWhere(
          (s) => s.searchQuery == 'Foldex[4]',
        );
        await tester.enterText(find.byType(TextField), 'Foldex[4]');
        await tester.runAsync(() => queryFoldex);
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byType(BreedCard),
            matching: find.text('Foldex[4]'),
          ),
          findsOneWidget,
        );
        expect(
          find.text('PerFoldæ(Experimental Breed - WCF)'),
          findsNothing,
        );

        final queryDonskoy = bloc.stream.firstWhere(
          (s) => s.searchQuery == 'don sphynx',
        );
        await tester.enterText(find.byType(TextField), 'don sphynx');
        await tester.runAsync(() => queryDonskoy);
        await tester.pumpAndSettle();

        expect(find.text('Donskoy, or Don Sphynx'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );

    testWidgets(
      'post-frame scroll check triggers next page on tall viewport and after Pull-to-Refresh (A3 UI)',
      (tester) async {
        _setViewport(tester, const Size(1024, 1366));

        var page2Calls = 0;
        when(
          () => repository.fetchBreedsPage(
            page: 1,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer(
          (_) async => const BreedsPage(
            currentPage: 1,
            lastPage: 2,
            total: 4,
            items: [_abyssinian, _bengal],
          ),
        );
        when(
          () => repository.fetchBreedsPage(
            page: 2,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async {
          page2Calls++;
          return const BreedsPage(
            currentPage: 2,
            lastPage: 2,
            total: 4,
            items: [foldexBreed, donskoyBreed],
          );
        });

        final router = createAppRouter(
          detailCubitFactory: () => BreedDetailCubit(repository: repository),
        );
        addTearDown(router.dispose);

        final reachedPage1 = bloc.stream.firstWhere(
          (s) => s.status == BreedsStatus.loaded && s.currentPage == 1,
        );
        final reachedPage2 = bloc.stream.firstWhere(
          (s) => s.currentPage == 2 && !s.isLoadingMore,
        );

        await tester.pumpWidget(
          CatDirectoryApp(breedsBloc: bloc, router: router),
        );
        await tester.runAsync(() => reachedPage1);
        await tester.pump();
        await tester.pump();
        await tester.runAsync(() => reachedPage2);
        await tester.pumpAndSettle();

        expect(page2Calls, 1);
        expect(find.text('Abyssinian'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(BreedCard),
            matching: find.text('Foldex[4]'),
          ),
          findsOneWidget,
        );
        expect(find.text('Donskoy, or Don Sphynx'), findsOneWidget);

        // Pull-to-Refresh resets to page 1 (hasMore: true); post-frame check
        // must automatically fetch page 2 again without manual downward scroll.
        final refreshedPage1 = bloc.stream.firstWhere(
          (s) => s.currentPage == 1 && !s.isRevalidating,
        );
        final reachedPage2Again = bloc.stream.firstWhere(
          (s) => s.currentPage == 2 && !s.isLoadingMore && !s.isRevalidating,
        );
        await tester.fling(
          find.byType(CustomScrollView),
          const Offset(0, 350),
          1000,
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.runAsync(() => refreshedPage1);
        await tester.pump();
        await tester.pump();
        await tester.runAsync(() => reachedPage2Again);
        await tester.pumpAndSettle();

        expect(page2Calls, 2);
        expect(
          find.descendant(
            of: find.byType(BreedCard),
            matching: find.text('Foldex[4]'),
          ),
          findsOneWidget,
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );

    testWidgets(
      'ConnectivityStatusBanner Reintentar dispatches BreedsStarted when breeds.isEmpty (M6 UI)',
      (tester) async {
        var online = false;
        when(() => connectivity.hasConnection).thenAnswer((_) async => online);
        when(
          () => repository.fetchBreedsPage(
            page: 1,
            cancelToken: any(named: 'cancelToken'),
          ),
        ).thenAnswer((_) async {
          if (!online) {
            throw const NetworkFailure();
          }
          return const BreedsPage(
            currentPage: 1,
            lastPage: 1,
            total: 1,
            items: [_abyssinian],
          );
        });

        final router = createAppRouter(
          detailCubitFactory: () => BreedDetailCubit(repository: repository),
        );
        addTearDown(router.dispose);

        final reachedFailure = bloc.stream.firstWhere(
          (s) => s.status == BreedsStatus.failure,
        );
        await tester.pumpWidget(
          CatDirectoryApp(breedsBloc: bloc, router: router),
        );
        await tester.runAsync(() => reachedFailure);
        await tester.pumpAndSettle();

        expect(bloc.state.breeds, isEmpty);
        final bannerRetryButton = find.descendant(
          of: find.byType(ConnectivityStatusBanner),
          matching: find.text('Reintentar'),
        );
        expect(bannerRetryButton, findsOneWidget);

        // Restore connectivity and tap Reintentar in the banner.
        online = true;
        final reachedLoading = bloc.stream.firstWhere(
          (s) => s.status == BreedsStatus.loading,
        );
        final reachedLoaded = bloc.stream.firstWhere(
          (s) => s.status == BreedsStatus.loaded && s.breeds.isNotEmpty,
        );

        await tester.tap(bannerRetryButton);
        await tester.runAsync(() async {
          await reachedLoading;
          await reachedLoaded;
        });
        await tester.pumpAndSettle();

        expect(find.text('Abyssinian'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );

    testWidgets(
      'AppBar chip Semantics and PaginationFooter avoid "de 0" when total == 0 (B6)',
      (tester) async {
        final handle = tester.ensureSemantics();

        bloc.emit(
          const BreedsState(
            status: BreedsStatus.loaded,
            breeds: [_abyssinian, _bengal],
            searchQuery: 'Aby',
            currentPage: 1,
            lastPage: 2,
            total: 0,
            isOnline: true,
          ),
        );

        await tester.pumpWidget(
          BlocProvider<BreedsBloc>.value(
            value: bloc,
            child: MaterialApp(
              theme: AppTheme.light(),
              home: const BreedsListPage(),
            ),
          ),
        );
        await tester.pump();

        expect(
          find.bySemanticsLabel('2 razas cargadas, en línea'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(RegExp('de 0')),
          findsNothing,
        );
        expect(
          find.text('Filtrando sobre 2 razas cargadas en memoria'),
          findsOneWidget,
        );
        expect(find.textContaining('de 0'), findsNothing);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        handle.dispose();
      },
    );
  });
}
