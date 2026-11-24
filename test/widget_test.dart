import 'package:cat_directory_app/app.dart';
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
        items: [
          Breed(
            breed: 'Abyssinian',
            country: 'Ethiopia',
            origin: 'Natural/Standard',
            coat: 'Short',
            pattern: 'Ticked',
          ),
        ],
      ),
    );
    when(() => repository.findBreedByName('Abyssinian')).thenAnswer(
      (_) async => const Breed(
        breed: 'Abyssinian',
        country: 'Ethiopia',
        origin: 'Natural/Standard',
        coat: 'Short',
        pattern: 'Ticked',
      ),
    );
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

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
