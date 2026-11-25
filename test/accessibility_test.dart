import 'dart:async';

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
import 'package:cat_directory_app/features/breeds/presentation/bloc/breeds_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockBreedsRepository extends Mock implements BreedsRepository {}

class _MockConnectivityMonitor extends Mock implements ConnectivityMonitor {}

void main() {
  const sampleBreed = Breed(
    breed: 'Abyssinian',
    country: 'Ethiopia',
    origin: 'Natural/Standard',
    coat: 'Short',
    pattern: 'Ticked',
  );

  group('Accessibility Semantics audit', () {
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
          lastPage: 2,
          total: 40,
          items: [sampleBreed],
        ),
      );
      when(() => repository.findBreedByName('Abyssinian'))
          .thenAnswer((_) async => sampleBreed);
      when(() => repository.fetchRandomFact()).thenAnswer(
        (_) async =>
            const CatFact(fact: 'Cats have 32 muscles in each ear.', length: 33),
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
        'Home screen exposes Semantics labels and satisfies tap-target guidelines',
        (tester) async {
      final handle = tester.ensureSemantics();
      final router = createAppRouter(
        detailCubitFactory: () => BreedDetailCubit(repository: repository),
      );
      addTearDown(router.dispose);

      // Subscribe before pumpWidget so the emission can never be missed.
      final reachedLoaded = bloc.stream.firstWhere(
        (s) => s.status == BreedsStatus.loaded,
      );

      await tester.pumpWidget(CatDirectoryApp(breedsBloc: bloc, router: router));
      await tester.runAsync(() => reachedLoaded);
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(RegExp('Buscar raza de gato')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          RegExp('Raza Abyssinian, país de origen Ethiopia'),
        ),
        findsOneWidget,
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      handle.dispose();
    });

    testWidgets('Loading skeleton exposes live-region Semantics label',
        (tester) async {
      final completer = Completer<BreedsPage>();
      when(() => repository.fetchBreedsPage(page: any(named: 'page')))
          .thenAnswer((_) => completer.future);

      final handle = tester.ensureSemantics();
      final router = createAppRouter(
        detailCubitFactory: () => BreedDetailCubit(repository: repository),
      );
      addTearDown(router.dispose);

      final reachedLoading = bloc.stream.firstWhere(
        (s) => s.status == BreedsStatus.loading,
      );

      await tester.pumpWidget(CatDirectoryApp(breedsBloc: bloc, router: router));
      await tester.runAsync(() => reachedLoading);
      await tester.pump();

      expect(
        find.bySemanticsLabel('Cargando directorio de razas de gatos'),
        findsOneWidget,
      );

      completer.complete(
        const BreedsPage(
          currentPage: 1,
          lastPage: 1,
          total: 1,
          items: [sampleBreed],
        ),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      handle.dispose();
    });

    testWidgets('Error state exposes accessible retry action and guidelines',
        (tester) async {
      when(() => repository.fetchBreedsPage(page: any(named: 'page')))
          .thenThrow(const NetworkFailure());

      final handle = tester.ensureSemantics();
      final router = createAppRouter(
        detailCubitFactory: () => BreedDetailCubit(repository: repository),
      );
      addTearDown(router.dispose);

      final reachedFailure = bloc.stream.firstWhere(
        (s) => s.status == BreedsStatus.failure,
      );

      await tester.pumpWidget(CatDirectoryApp(breedsBloc: bloc, router: router));
      await tester.runAsync(() => reachedFailure);
      await tester.pumpAndSettle();

      expect(find.text('Reintentar'), findsOneWidget);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      handle.dispose();
    });
  });
}
