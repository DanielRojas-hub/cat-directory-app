import 'package:cat_directory_app/core/errors/app_failure.dart';
import 'package:cat_directory_app/core/storage/cache_envelope.dart';
import 'package:cat_directory_app/features/breeds/data/datasources/breeds_local_datasource.dart';
import 'package:cat_directory_app/features/breeds/data/datasources/breeds_remote_datasource.dart';
import 'package:cat_directory_app/features/breeds/data/models/breed_model.dart';
import 'package:cat_directory_app/features/breeds/data/models/breeds_page_model.dart';
import 'package:cat_directory_app/features/breeds/data/models/cat_fact_model.dart';
import 'package:cat_directory_app/features/breeds/data/repositories/breeds_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockRemoteDataSource extends Mock implements BreedsRemoteDataSource {}

class _MockLocalDataSource extends Mock implements BreedsLocalDataSource {}

void main() {
  group('BreedsRepositoryImpl (TTL cache & Deep Link lookup)', () {
    late _MockRemoteDataSource remoteDataSource;
    late BreedsLocalDataSourceImpl localDataSource;
    late DateTime currentTime;

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
      ],
    );

    const page2Model = BreedsPageModel(
      currentPage: 2,
      lastPage: 2,
      total: 2,
      data: [
        BreedModel(
          breed: 'Somali',
          country: 'Somalia',
          origin: 'Mutation',
          coat: 'Long',
          pattern: 'Ticked',
        ),
      ],
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      remoteDataSource = _MockRemoteDataSource();
      localDataSource = BreedsLocalDataSourceImpl(
        SharedPreferencesCacheStore(prefs),
        ttl: const Duration(minutes: 10),
      );
      currentTime = DateTime.now().toUtc();
    });

    test('persists page 1 with explicit TTL and detects expiration accurately',
        () async {
      when(
        () => remoteDataSource.fetchBreedsPage(page: 1, limit: 20),
      ).thenAnswer((_) async => page1Model);

      final repository = BreedsRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
        clock: () => currentTime,
      );

      await repository.fetchBreedsPage(page: 1);

      final freshCache = repository.getCachedFirstPage();
      expect(freshCache, isNotNull);
      expect(freshCache!.page.items.first.breed, 'Abyssinian');
      expect(freshCache.isExpired, isFalse);

      // Advance clock beyond the 10-minute TTL.
      currentTime = currentTime.add(const Duration(minutes: 11));
      final staleCache = repository.getCachedFirstPage();
      expect(staleCache, isNotNull);
      expect(staleCache!.isExpired, isTrue);
    });

    test('invalidateCache explicitly clears persisted page 1', () async {
      when(
        () => remoteDataSource.fetchBreedsPage(page: 1, limit: 20),
      ).thenAnswer((_) async => page1Model);

      final repository = BreedsRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );

      await repository.fetchBreedsPage(page: 1);
      expect(repository.getCachedFirstPage(), isNotNull);

      await repository.invalidateCache();
      expect(repository.getCachedFirstPage(), isNull);
    });

    test('findBreedByName falls back to paginated remote lookup for cold Deep Links',
        () async {
      when(
        () => remoteDataSource.fetchBreedsPage(page: 1, limit: 50),
      ).thenAnswer((_) async => page1Model);
      when(
        () => remoteDataSource.fetchBreedsPage(page: 2, limit: 50),
      ).thenAnswer((_) async => page2Model);

      final repository = BreedsRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );

      final found = await repository.findBreedByName('Somali');
      expect(found.breed, 'Somali');
      expect(found.country, 'Somalia');

      await expectLater(
        () => repository.findBreedByName('NonExistentBreed'),
        throwsA(isA<NotFoundFailure>()),
      );
    });

    test('findBreedByName stops at maxLookupPages when API returns anomalous lastPage',
        () async {
      when(
        () => remoteDataSource.fetchBreedsPage(
          page: any(named: 'page'),
          limit: 50,
        ),
      ).thenAnswer(
        (invocation) async => BreedsPageModel(
          currentPage: invocation.namedArguments[#page] as int,
          lastPage: 9999,
          total: 500000,
          data: page1Model.data,
        ),
      );

      final repository = BreedsRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
        maxLookupPages: 3,
      );

      await expectLater(
        () => repository.findBreedByName('MissingBreed'),
        throwsA(isA<NotFoundFailure>()),
      );

      verify(
        () => remoteDataSource.fetchBreedsPage(
          page: any(named: 'page'),
          limit: 50,
        ),
      ).called(3);
    });

    test('findBreedByName enforces defaultMaxLookupPages safety bound',
        () async {
      when(
        () => remoteDataSource.fetchBreedsPage(
          page: any(named: 'page'),
          limit: 50,
        ),
      ).thenAnswer(
        (invocation) async => BreedsPageModel(
          currentPage: invocation.namedArguments[#page] as int,
          lastPage: 10000,
          total: 500000,
          data: const [],
        ),
      );

      final repository = BreedsRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );

      await expectLater(
        () => repository.findBreedByName('MissingBreed'),
        throwsA(isA<NotFoundFailure>()),
      );

      verify(
        () => remoteDataSource.fetchBreedsPage(
          page: any(named: 'page'),
          limit: 50,
        ),
      ).called(BreedsRepositoryImpl.defaultMaxLookupPages);
    });

    test('findBreedByName throws NotFoundFailure immediately for blank names',
        () async {
      final repository = BreedsRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );

      await expectLater(
        () => repository.findBreedByName('   '),
        throwsA(isA<NotFoundFailure>()),
      );

      verifyNever(
        () => remoteDataSource.fetchBreedsPage(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      );
    });

    test('does not persist or overwrite cached page 1 when remote returns data: []',
        () async {
      const emptyPage1 = BreedsPageModel(
        currentPage: 1,
        lastPage: 1,
        total: 0,
        data: [],
      );
      var calls = 0;
      when(
        () => remoteDataSource.fetchBreedsPage(page: 1, limit: 20),
      ).thenAnswer((_) async {
        calls++;
        return calls == 1 ? page1Model : emptyPage1;
      });

      final repository = BreedsRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );

      // Seed valid offline backup first.
      await repository.fetchBreedsPage(page: 1);
      expect(repository.getCachedFirstPage()?.page.items.length, 1);

      // Subsequent empty page 1 must NOT poison persisted cache.
      final emptyResult = await repository.fetchBreedsPage(page: 1);
      expect(emptyResult.items, isEmpty);

      final preservedCache = repository.getCachedFirstPage();
      expect(preservedCache, isNotNull);
      expect(preservedCache!.page.items.single.breed, 'Abyssinian');
    });

    test('absorbs saveFirstPage write failures (best-effort) without failing HTTP 200 response',
        () async {
      final failingLocal = _MockLocalDataSource();
      when(() => failingLocal.saveFirstPage(page1Model))
          .thenThrow(Exception('Disk full'));
      when(
        () => remoteDataSource.fetchBreedsPage(page: 1, limit: 20),
      ).thenAnswer((_) async => page1Model);

      final repository = BreedsRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: failingLocal,
      );

      final page = await repository.fetchBreedsPage(page: 1);
      expect(page.items.single.breed, 'Abyssinian');
      verify(() => failingLocal.saveFirstPage(page1Model)).called(1);
    });

    test('invalidateCache clears both local cache and in-memory index',
        () async {
      when(
        () => remoteDataSource.fetchBreedsPage(page: 1, limit: 20),
      ).thenAnswer((_) async => page1Model);
      when(
        () => remoteDataSource.fetchBreedsPage(page: 1, limit: 50),
      ).thenAnswer(
        (_) async => const BreedsPageModel(
          currentPage: 1,
          lastPage: 1,
          total: 0,
          data: [],
        ),
      );

      final repository = BreedsRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );

      await repository.fetchBreedsPage(page: 1);
      expect((await repository.findBreedByName('Abyssinian')).breed, 'Abyssinian');

      await repository.invalidateCache();
      expect(repository.getCachedFirstPage(), isNull);

      // Must not resolve stale in-memory Abyssinian after invalidation.
      await expectLater(
        () => repository.findBreedByName('Abyssinian'),
        throwsA(isA<NotFoundFailure>()),
      );
    });

    test('forwards CancelToken to remote datasource and stops cancelled deep-link lookup',
        () async {
      final token = CancelToken();
      when(
        () => remoteDataSource.fetchBreedsPage(
          page: 1,
          limit: 20,
          cancelToken: token,
        ),
      ).thenAnswer((_) async => page1Model);
      when(
        () => remoteDataSource.fetchRandomFact(cancelToken: token),
      ).thenAnswer(
        (_) async => const CatFactModel(fact: 'Cats purr.', length: 10),
      );

      final repository = BreedsRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );

      await repository.fetchBreedsPage(page: 1, cancelToken: token);
      final fact = await repository.fetchRandomFact(cancelToken: token);
      expect(fact.fact, 'Cats purr.');

      verify(
        () => remoteDataSource.fetchBreedsPage(
          page: 1,
          limit: 20,
          cancelToken: token,
        ),
      ).called(1);
      verify(
        () => remoteDataSource.fetchRandomFact(cancelToken: token),
      ).called(1);

      final cancelledToken = CancelToken()..cancel('Aborted');
      await expectLater(
        () => repository.findBreedByName(
          'NotInMemory',
          cancelToken: cancelledToken,
        ),
        throwsA(
          isA<AppFailure>().having((f) => f.isCancellation, 'isCancellation', true),
        ),
      );
    });
  });
}
