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
import 'package:cat_directory_app/features/breeds/presentation/pages/breed_detail_page.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockBreedsRepository extends Mock implements BreedsRepository {}

class _MockConnectivityMonitor extends Mock implements ConnectivityMonitor {}

SemanticsOwner _semanticsOwner(WidgetTester tester) {
  return tester
      .renderObject(find.byType(CatDirectoryApp))
      .owner!
      .semanticsOwner!;
}

List<SemanticsNode> _collectSemanticsNodes(WidgetTester tester) {
  final root = _semanticsOwner(tester).rootSemanticsNode;
  final nodes = <SemanticsNode>[];
  if (root == null) return nodes;

  void visit(SemanticsNode node) {
    nodes.add(node);
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(root);
  return nodes;
}

void main() {
  const sampleBreed = Breed(
    breed: 'Abyssinian',
    country: 'Ethiopia',
    origin: 'Natural/Standard',
    coat: 'Short',
    pattern: 'Ticked',
  );

  const secondBreed = Breed(
    breed: 'Bengal',
    country: 'United States',
    origin: 'Hybrid',
    coat: 'Short',
    pattern: 'Spotted',
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

      final textFieldNodes = _collectSemanticsNodes(tester)
          .where((node) => node.getSemanticsData().flagsCollection.isTextField)
          .toList();
      expect(textFieldNodes, hasLength(1));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      handle.dispose();
    });

    testWidgets(
        'Search field exposes single textField node and independent clear button via SemanticsAction.tap',
        (tester) async {
      when(() => repository.fetchBreedsPage(page: any(named: 'page')))
          .thenAnswer(
        (_) async => const BreedsPage(
          currentPage: 1,
          lastPage: 1,
          total: 2,
          items: [sampleBreed, secondBreed],
        ),
      );

      final handle = tester.ensureSemantics();
      final router = createAppRouter(
        detailCubitFactory: () => BreedDetailCubit(repository: repository),
      );
      addTearDown(router.dispose);

      final reachedLoaded = bloc.stream.firstWhere(
        (s) => s.status == BreedsStatus.loaded,
      );

      await tester.pumpWidget(CatDirectoryApp(breedsBloc: bloc, router: router));
      await tester.runAsync(() => reachedLoaded);
      await tester.pumpAndSettle();

      final reachedFiltered = bloc.stream.firstWhere(
        (s) => s.searchQuery == 'Aby',
      );
      await tester.enterText(find.byType(TextField), 'Aby');
      await tester.runAsync(() => reachedFiltered);
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(
          RegExp('Raza Abyssinian, país de origen Ethiopia'),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          RegExp('Raza Bengal, país de origen United States'),
        ),
        findsNothing,
      );

      // Ensure no duplicate textField node wraps EditableText or suffixIcon.
      final textFieldNodes = _collectSemanticsNodes(tester)
          .where((node) => node.getSemanticsData().flagsCollection.isTextField)
          .toList();
      expect(textFieldNodes, hasLength(1));

      final clearTooltipFinder = find.byTooltip('Limpiar búsqueda');
      expect(clearTooltipFinder, findsOneWidget);

      final clearNode = tester.semantics.find(clearTooltipFinder);
      final clearData = clearNode.getSemanticsData();
      expect(clearNode.id, isNot(textFieldNodes.single.id));
      expect(clearData.flagsCollection.isButton, isTrue);
      expect(clearData.flagsCollection.isTextField, isFalse);
      expect(clearData.hasAction(SemanticsAction.tap), isTrue);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      final reachedCleared = bloc.stream.firstWhere(
        (s) => s.searchQuery.isEmpty,
      );
      _semanticsOwner(tester).performAction(
        clearNode.id,
        SemanticsAction.tap,
      );
      await tester.runAsync(() => reachedCleared);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Limpiar búsqueda'), findsNothing);
      expect(
        find.bySemanticsLabel(
          RegExp('Raza Bengal, país de origen United States'),
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      handle.dispose();
    });

    testWidgets(
        'BreedCard exposes SemanticsAction.tap and navigates to BreedDetailPage',
        (tester) async {
      final handle = tester.ensureSemantics();
      final router = createAppRouter(
        detailCubitFactory: () => BreedDetailCubit(repository: repository),
      );
      addTearDown(router.dispose);

      final reachedLoaded = bloc.stream.firstWhere(
        (s) => s.status == BreedsStatus.loaded,
      );

      await tester.pumpWidget(CatDirectoryApp(breedsBloc: bloc, router: router));
      await tester.runAsync(() => reachedLoaded);
      await tester.pumpAndSettle();

      final breedCardFinder = find.semantics.byLabel(
        RegExp('Raza Abyssinian, país de origen Ethiopia'),
      );
      expect(breedCardFinder, findsOneWidget);

      final cardData = breedCardFinder.evaluate().single.getSemanticsData();
      expect(cardData.flagsCollection.isButton, isTrue);
      expect(cardData.hasAction(SemanticsAction.tap), isTrue);

      tester.semantics.tap(breedCardFinder);
      await tester.pumpAndSettle();

      expect(find.byType(BreedDetailPage), findsOneWidget);
      expect(find.text('Ficha de la Raza'), findsOneWidget);
      expect(find.text('Dato Curioso Aleatorio'), findsOneWidget);
      expect(find.text('“Cats have 32 muscles in each ear.”'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      handle.dispose();
    });

    testWidgets(
        'BreedDetailPage satisfies accessibility guidelines and CatFactCard refresh has single button node',
        (tester) async {
      var factCallCount = 0;
      when(() => repository.fetchRandomFact()).thenAnswer((_) async {
        factCallCount++;
        if (factCallCount == 1) {
          return const CatFact(
            fact: 'Cats have 32 muscles in each ear.',
            length: 33,
          );
        }
        return const CatFact(
          fact: 'Cats can rotate their ears 180 degrees.',
          length: 39,
        );
      });

      final handle = tester.ensureSemantics();
      final router = createAppRouter(
        initialLocation: AppRoutes.breedDetailPath('Abyssinian'),
        detailCubitFactory: () => BreedDetailCubit(repository: repository),
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(CatDirectoryApp(breedsBloc: bloc, router: router));
      await tester.pumpAndSettle();

      expect(find.byType(BreedDetailPage), findsOneWidget);
      expect(find.text('“Cats have 32 muscles in each ear.”'), findsOneWidget);

      // Verify single semantic button node for CatFactCard reload (no duplicate wrapper).
      final refreshNodes = _collectSemanticsNodes(tester).where((node) {
        final data = node.getSemanticsData();
        return data.tooltip.contains('Cargar otro dato curioso') ||
            data.label.contains('Cargar otro dato curioso');
      }).toList();
      expect(refreshNodes, hasLength(1));

      final refreshNode = refreshNodes.single;
      final refreshData = refreshNode.getSemanticsData();
      expect(refreshData.flagsCollection.isButton, isTrue);
      expect(refreshData.hasAction(SemanticsAction.tap), isTrue);
      expect(
        refreshNode.parent?.getSemanticsData().flagsCollection.isButton,
        isNot(true),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      final refreshButtonFinder = find.byTooltip(
        'Cargar otro dato curioso aleatorio',
      );
      expect(refreshButtonFinder, findsOneWidget);

      _semanticsOwner(tester).performAction(
        refreshNode.id,
        SemanticsAction.tap,
      );
      await tester.pumpAndSettle();

      expect(factCallCount, 2);
      expect(
        find.text('“Cats can rotate their ears 180 degrees.”'),
        findsOneWidget,
      );

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
