import 'package:cat_directory_app/app.dart';
import 'package:cat_directory_app/core/network/connectivity_monitor.dart';
import 'package:cat_directory_app/core/router/app_router.dart';
import 'package:cat_directory_app/features/breeds/domain/entities/breed.dart';
import 'package:cat_directory_app/features/breeds/domain/entities/breeds_page.dart';
import 'package:cat_directory_app/features/breeds/domain/entities/cat_fact.dart';
import 'package:cat_directory_app/features/breeds/domain/repositories/breeds_repository.dart';
import 'package:cat_directory_app/features/breeds/presentation/bloc/breed_detail_cubit.dart';
import 'package:cat_directory_app/features/breeds/presentation/bloc/breeds_bloc.dart';
import 'package:cat_directory_app/features/breeds/presentation/bloc/breeds_state.dart';
import 'package:cat_directory_app/features/breeds/presentation/widgets/breed_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockBreedsRepository extends Mock implements BreedsRepository {}

class _MockConnectivityMonitor extends Mock implements ConnectivityMonitor {}

List<Breed> _generateBreeds(int count) {
  return List<Breed>.generate(
    count,
    (index) => Breed(
      breed: 'Cat Breed ${(index + 1).toString().padLeft(2, '0')}',
      country: index.isEven ? 'Ethiopia' : 'Japan',
      origin: 'Natural',
      coat: index.isEven ? 'Short' : 'Long',
      pattern: 'Tabby',
    ),
  );
}

void main() {
  const totalBreeds = 98;
  const pageSize = 20;
  const lastPage = 5;
  final allBreeds = _generateBreeds(totalBreeds);

  group('Directory scroll & theme regression (98 breeds)', () {
    late _MockBreedsRepository repository;
    late _MockConnectivityMonitor connectivity;
    late BreedsBloc bloc;

    setUp(() {
      repository = _MockBreedsRepository();
      connectivity = _MockConnectivityMonitor();

      when(() => connectivity.hasConnection).thenAnswer((_) async => true);
      when(() => connectivity.onStatusChanged).thenAnswer(
        (_) => const Stream<bool>.empty(),
      );
      when(() => repository.getCachedFirstPage()).thenReturn(null);
      when(
        () => repository.fetchBreedsPage(
          page: any(named: 'page'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((invocation) async {
        final page = invocation.namedArguments[#page] as int;
        final start = (page - 1) * pageSize;
        final end = (start + pageSize).clamp(0, totalBreeds);
        return BreedsPage(
          currentPage: page,
          lastPage: lastPage,
          total: totalBreeds,
          items: allBreeds.sublist(start, end),
        );
      });
      when(
        () => repository.fetchRandomFact(
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => const CatFact(
          fact: 'A group of cats is called a clowder.',
          length: 36,
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

    testWidgets(
      'paginates all 98 breeds and sustains >200 scroll frames without errors',
      (tester) async {
        final router = createAppRouter(
          detailCubitFactory: () => BreedDetailCubit(repository: repository),
        );
        addTearDown(router.dispose);

        final firstPageLoaded = bloc.stream
            .firstWhere(
              (s) =>
                  s.status == BreedsStatus.loaded &&
                  s.breeds.length == pageSize,
            )
            .timeout(const Duration(seconds: 3));

        await tester.pumpWidget(
          CatDirectoryApp(breedsBloc: bloc, router: router),
        );
        await tester.runAsync(() => firstPageLoaded);
        await tester.pumpAndSettle();

        final scrollable = find.byType(CustomScrollView);
        expect(scrollable, findsOneWidget);
        expect(find.text('20/98'), findsOneWidget);

        // Paginate downward through pages 2..5 until all 98 breeds are loaded.
        final endFooter = find.text('Fin del directorio · 98 razas exploradas');
        for (var step = 0; step < 30 && endFooter.evaluate().isEmpty; step++) {
          await tester.drag(scrollable, const Offset(0, -1500));
          await tester.pump();
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await tester.pump();
        }

        expect(bloc.state.breeds.length, totalBreeds);
        expect(find.text('98/98'), findsOneWidget);
        expect(endFooter, findsOneWidget);

        // Sustained bidirectional scroll pumping >200 continuous 16 ms frames.
        const frameInterval = Duration(milliseconds: 16);
        var pumpedFrames = 0;

        for (var cycle = 0; cycle < 2; cycle++) {
          await tester.timedDrag(
            scrollable,
            const Offset(0, 1000),
            const Duration(milliseconds: 640),
            frequency: 60.0,
          );
          pumpedFrames += 38;
          await tester.fling(scrollable, const Offset(0, 1000), 2000);
          for (var f = 0; f < 20; f++) {
            await tester.pump(frameInterval);
            pumpedFrames++;
          }

          await tester.timedDrag(
            scrollable,
            const Offset(0, -1000),
            const Duration(milliseconds: 640),
            frequency: 60.0,
          );
          pumpedFrames += 38;
          await tester.fling(scrollable, const Offset(0, -1000), 2000);
          for (var f = 0; f < 20; f++) {
            await tester.pump(frameInterval);
            pumpedFrames++;
          }
        }

        for (var i = 0; i < 10; i++) {
          await tester.pump(frameInterval);
        }
        expect(pumpedFrames, greaterThan(200));
        expect(find.byType(BreedCard), findsWidgets);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );

    testWidgets(
      'renders breeds directory cleanly in both Light and Dark system modes',
      (tester) async {
        final router = createAppRouter(
          detailCubitFactory: () => BreedDetailCubit(repository: repository),
        );
        addTearDown(router.dispose);

        final firstPageLoaded = bloc.stream
            .firstWhere((s) => s.status == BreedsStatus.loaded)
            .timeout(const Duration(seconds: 3));

        tester.platformDispatcher.platformBrightnessTestValue =
            Brightness.light;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

        await tester.pumpWidget(
          CatDirectoryApp(breedsBloc: bloc, router: router),
        );
        await tester.runAsync(() => firstPageLoaded);
        await tester.pumpAndSettle();

        final lightContext = tester.element(find.byType(Scaffold));
        expect(Theme.of(lightContext).brightness, Brightness.light);
        expect(find.byType(BreedCard), findsWidgets);

        tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final darkContext = tester.element(find.byType(Scaffold));
        expect(Theme.of(darkContext).brightness, Brightness.dark);
        expect(find.byType(BreedCard), findsWidgets);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  });
}
