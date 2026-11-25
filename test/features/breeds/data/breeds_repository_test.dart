import 'package:cat_directory_app/core/errors/app_failure.dart';
import 'package:cat_directory_app/core/storage/cache_envelope.dart';
import 'package:cat_directory_app/features/breeds/data/datasources/breeds_local_datasource.dart';
import 'package:cat_directory_app/features/breeds/data/datasources/breeds_remote_datasource.dart';
import 'package:cat_directory_app/features/breeds/data/models/breed_model.dart';
import 'package:cat_directory_app/features/breeds/data/models/breeds_page_model.dart';
import 'package:cat_directory_app/features/breeds/data/repositories/breeds_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockRemoteDataSource extends Mock implements BreedsRemoteDataSource {}

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
  });
}
