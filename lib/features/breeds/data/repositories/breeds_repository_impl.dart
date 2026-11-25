import 'package:dio/dio.dart';

import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/breed.dart';
import '../../domain/entities/breeds_page.dart';
import '../../domain/entities/cached_breeds_result.dart';
import '../../domain/entities/cat_fact.dart';
import '../../domain/repositories/breeds_repository.dart';
import '../datasources/breeds_local_datasource.dart';
import '../datasources/breeds_remote_datasource.dart';

/// SWR repository coordinating remote Catfact Ninja API, TTL local cache
/// and an in-memory index for instant parameterized route resolution.
final class BreedsRepositoryImpl implements BreedsRepository {
  BreedsRepositoryImpl({
    required this._remoteDataSource,
    required this._localDataSource,
    DateTime Function()? clock,
    this.maxLookupPages = defaultMaxLookupPages,
  })  : assert(maxLookupPages > 0, 'maxLookupPages must be greater than zero.'),
        _clock = clock ?? DateTime.now;

  /// Upper bound on remote pages inspected during cold-start deep-link lookups.
  static const int defaultMaxLookupPages = 20;

  final BreedsRemoteDataSource _remoteDataSource;
  final BreedsLocalDataSource _localDataSource;
  final DateTime Function() _clock;
  final int maxLookupPages;

  final Map<String, Breed> _memoryIndex = <String, Breed>{};

  @override
  CachedBreedsResult? getCachedFirstPage() {
    final envelope = _localDataSource.readFirstPage();
    if (envelope == null) {
      return null;
    }

    final entity = envelope.data.toEntity();
    _indexBreeds(entity.items);

    return CachedBreedsResult(
      page: entity,
      cachedAt: envelope.cachedAt,
      isExpired: envelope.isExpired(_clock()),
    );
  }

  @override
  Future<BreedsPage> fetchBreedsPage({
    required int page,
    int limit = BreedsRepository.defaultPageSize,
    CancelToken? cancelToken,
  }) async {
    final model = cancelToken != null
        ? await _remoteDataSource.fetchBreedsPage(
            page: page,
            limit: limit,
            cancelToken: cancelToken,
          )
        : await _remoteDataSource.fetchBreedsPage(
            page: page,
            limit: limit,
          );

    if (page == 1 && model.data.isNotEmpty) {
      try {
        await _localDataSource.saveFirstPage(model);
      } on Object {
        // Best-effort local persistence: never fail a valid remote response.
      }
    }

    final entity = model.toEntity();
    if (page == 1 && model.data.isNotEmpty) {
      _memoryIndex.clear();
    }
    _indexBreeds(entity.items);
    return entity;
  }

  @override
  Future<void> invalidateCache() {
    _memoryIndex.clear();
    return _localDataSource.invalidate();
  }

  @override
  Future<Breed> findBreedByName(
    String name, {
    CancelToken? cancelToken,
  }) async {
    final normalized = _normalizeKey(name);
    if (normalized.isEmpty) {
      throw NotFoundFailure(
        message: 'No encontramos la raza "$name" en el directorio.',
      );
    }

    final inMemory = _memoryIndex[normalized];
    if (inMemory != null) {
      return inMemory;
    }

    final cached = getCachedFirstPage();
    if (cached != null) {
      final fromCache = _memoryIndex[normalized];
      if (fromCache != null) {
        return fromCache;
      }
    }

    // Fallback for cold-start Deep Links targeting a breed outside page 1.
    var currentPage = 1;
    var lastPage = 1;
    const lookupPageSize = 50;

    do {
      if (cancelToken?.isCancelled ?? false) {
        throw AppFailure.fromDioException(
          DioException.requestCancelled(
            requestOptions: RequestOptions(path: '/breeds'),
            reason: cancelToken?.cancelError?.error,
          ),
        );
      }

      final model = cancelToken != null
          ? await _remoteDataSource.fetchBreedsPage(
              page: currentPage,
              limit: lookupPageSize,
              cancelToken: cancelToken,
            )
          : await _remoteDataSource.fetchBreedsPage(
              page: currentPage,
              limit: lookupPageSize,
            );
      final entity = model.toEntity();
      _indexBreeds(entity.items);

      final found = _memoryIndex[normalized];
      if (found != null) {
        return found;
      }

      lastPage = entity.lastPage;
      currentPage++;
    } while (currentPage <= lastPage && currentPage <= maxLookupPages);

    throw NotFoundFailure(
      message: 'No encontramos la raza "$name" en el directorio.',
    );
  }

  @override
  Future<CatFact> fetchRandomFact({
    CancelToken? cancelToken,
  }) async {
    final model = cancelToken != null
        ? await _remoteDataSource.fetchRandomFact(cancelToken: cancelToken)
        : await _remoteDataSource.fetchRandomFact();
    return model.toEntity();
  }

  void _indexBreeds(Iterable<Breed> breeds) {
    for (final breed in breeds) {
      _memoryIndex[_normalizeKey(breed.breed)] = breed;
    }
  }

  String _normalizeKey(String input) => input.trim().toLowerCase();
}
