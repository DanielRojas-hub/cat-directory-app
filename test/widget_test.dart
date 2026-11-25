import 'package:cat_directory_app/app.dart';
import 'package:cat_directory_app/core/errors/app_failure.dart';
import 'package:cat_directory_app/core/network/connectivity_monitor.dart';
import 'package:cat_directory_app/core/router/app_router.dart';
import 'package:cat_directory_app/features/breeds/domain/entities/breed.dart';
import 'package:cat_directory_app/features/breeds/domain/entities/breeds_page.dart';
import 'package:cat_directory_app/features/breeds/domain/entities/cat_fact.dart';
import 'package:cat_directory_app/features/breeds/domain/repositories/breeds_repository.dart';
import 'package:cat_directory_app/features/breeds/presentation/bloc/breed_detail_cubit.dart';
import 'package:cat_directory_app/features/breeds/presentation/bloc/breeds_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockBreedsRepository extends Mock implements BreedsRepository {}

class _MockConnectivityMonitor extends Mock implements ConnectivityMonitor {}

void main() {
  const abyssinian = Breed(
    breed: 'Abyssinian',
    country: 'Ethiopia',
    origin: 'Natural/Standard',
    coat: 'Short',
    pattern: 'Ticked',
  );
  const bengal = Breed(
    breed: 'Bengal',
    country: 'United States',
    origin: 'Hybrid',
    coat: 'Short',
    pattern: 'Spotted',
  );
  const britishShorthair = Breed(
    breed: 'British Shorthair',
    country: 'United Kingdom',
    origin: 'Natural',
    coat: 'Short',
    pattern: 'All',
  );
  const bengalPercent = Breed(
    breed: 'Bengal 100%',
    country: 'United States',
    origin: 'Hybrid',
    coat: 'Short',
    pattern: 'Marbled',
  );
  const literalEncodedBreed = Breed(
    breed: 'Cat%20Test',
    country: 'Spain',
    origin: 'Custom',
    coat: 'Medium',
    pattern: 'Solid',
  );

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
    when(() => repository.fetchBreedsPage(page: any(named: 'page')))
        .thenAnswer(
      (_) async => const BreedsPage(
        currentPage: 1,
        lastPage: 1,
        total: 1,
        items: [abyssinian],
      ),
    );
    when(() => repository.findBreedByName('Abyssinian'))
        .thenAnswer((_) async => abyssinian);
    when(() => repository.findBreedByName('Bengal'))
        .thenAnswer((_) async => bengal);
    when(() => repository.findBreedByName('British Shorthair'))
        .thenAnswer((_) async => britishShorthair);
    when(() => repository.findBreedByName('Bengal 100%'))
        .thenAnswer((_) async => bengalPercent);
    when(() => repository.findBreedByName('Cat%20Test'))
        .thenAnswer((_) async => literalEncodedBreed);
    when(() => repository.fetchRandomFact()).thenAnswer(
      (_) async => const CatFact(fact: 'Cats sleep 12-16 hours a day.', length: 30),
    );

    bloc = BreedsBloc(
      repository: repository,
      connectivityMonitor: connectivity,
    );
  });

  tearDown(() async {
    await bloc.close();
  });

  testWidgets('App resolves parameterized /breed/:name route via GoRouter',
      (tester) async {
    final router = createAppRouter(
      initialLocation: AppRoutes.breedDetailPath('Abyssinian'),
      detailCubitFactory: () => BreedDetailCubit(repository: repository),
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      CatDirectoryApp(breedsBloc: bloc, router: router),
    );
    await tester.pumpAndSettle();

    expect(find.text('Abyssinian'), findsAtLeastNWidgets(1));
    expect(find.text('Ethiopia'), findsAtLeastNWidgets(1));
    expect(find.text('Ticked'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
      'Hot navigation /breed/Abyssinian -> /breed/Bengal recreates cubit and updates full UI',
      (tester) async {
    final router = createAppRouter(
      initialLocation: AppRoutes.breedDetailPath('Abyssinian'),
      detailCubitFactory: () => BreedDetailCubit(repository: repository),
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      CatDirectoryApp(breedsBloc: bloc, router: router),
    );
    await tester.pumpAndSettle();

    expect(find.text('Abyssinian'), findsAtLeastNWidgets(1));
    expect(find.text('Ethiopia'), findsAtLeastNWidgets(1));
    expect(find.text('Ticked'), findsOneWidget);

    router.go(AppRoutes.breedDetailPath('Bengal'));
    await tester.pumpAndSettle();

    expect(find.text('Bengal'), findsAtLeastNWidgets(1));
    expect(find.text('United States'), findsAtLeastNWidgets(1));
    expect(find.text('Hybrid'), findsOneWidget);
    expect(find.text('Spotted'), findsOneWidget);
    expect(find.text('Abyssinian'), findsNothing);
    expect(find.text('Ethiopia'), findsNothing);

    verify(() => repository.findBreedByName('Abyssinian')).called(1);
    verify(() => repository.findBreedByName('Bengal')).called(1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
      'Safely handles breed names with spaces and % without double decoding or ArgumentError',
      (tester) async {
    final router = createAppRouter(
      initialLocation: AppRoutes.breedDetailPath('British Shorthair'),
      detailCubitFactory: () => BreedDetailCubit(repository: repository),
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      CatDirectoryApp(breedsBloc: bloc, router: router),
    );
    await tester.pumpAndSettle();

    expect(find.text('British Shorthair'), findsAtLeastNWidgets(1));
    expect(find.text('United Kingdom'), findsAtLeastNWidgets(1));
    verify(() => repository.findBreedByName('British Shorthair')).called(1);

    // Percent sign in breed name must not trigger ArgumentError via double decode.
    router.go(AppRoutes.breedDetailPath('Bengal 100%'));
    await tester.pumpAndSettle();

    expect(find.text('Bengal 100%'), findsAtLeastNWidgets(1));
    expect(find.text('Marbled'), findsOneWidget);
    verify(() => repository.findBreedByName('Bengal 100%')).called(1);

    // Literal '%20' must be decoded once to 'Cat%20Test', not 'Cat Test'.
    router.go(AppRoutes.breedDetailPath('Cat%20Test'));
    await tester.pumpAndSettle();

    expect(find.text('Cat%20Test'), findsAtLeastNWidgets(1));
    expect(find.text('Spain'), findsAtLeastNWidgets(1));
    verify(() => repository.findBreedByName('Cat%20Test')).called(1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
      'Custom scheme deep link catdirectory://breed/... resolves encoded names and hot switches',
      (tester) async {
    final router = createAppRouter(
      initialLocation: 'catdirectory://breed/British%20Shorthair',
      detailCubitFactory: () => BreedDetailCubit(repository: repository),
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      CatDirectoryApp(breedsBloc: bloc, router: router),
    );
    await tester.pumpAndSettle();

    expect(find.text('British Shorthair'), findsAtLeastNWidgets(1));
    expect(find.text('United Kingdom'), findsAtLeastNWidgets(1));

    router.go('catdirectory://breed/Bengal%20100%25');
    await tester.pumpAndSettle();

    expect(find.text('Bengal 100%'), findsAtLeastNWidgets(1));
    expect(find.text('Marbled'), findsOneWidget);
    expect(find.text('British Shorthair'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
      'Cold-start detail screen retries breed lookup when tapping Reintentar',
      (tester) async {
    var attempts = 0;
    when(() => repository.findBreedByName('Bengal')).thenAnswer((_) async {
      attempts++;
      if (attempts == 1) {
        throw const NetworkFailure();
      }
      return bengal;
    });

    final router = createAppRouter(
      initialLocation: AppRoutes.breedDetailPath('Bengal'),
      detailCubitFactory: () => BreedDetailCubit(repository: repository),
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      CatDirectoryApp(breedsBloc: bloc, router: router),
    );
    await tester.pumpAndSettle();

    expect(find.text('No pudimos cargar "Bengal"'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Bengal'), findsAtLeastNWidgets(1));
    expect(find.text('United States'), findsAtLeastNWidgets(1));
    expect(find.text('Spotted'), findsOneWidget);
    expect(attempts, 2);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
