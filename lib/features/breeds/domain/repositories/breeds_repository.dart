import 'package:dio/dio.dart';

import '../entities/breed.dart';
import '../entities/breeds_page.dart';
import '../entities/cached_breeds_result.dart';
import '../entities/cat_fact.dart';

/// Contract for fetching, caching and looking up cat breeds and random facts.
abstract interface class BreedsRepository {
  /// Default page size used for infinite scroll requests.
  static const int defaultPageSize = 20;

  /// Reads the cached first page immediately if available (offline-first SWR).
  CachedBreedsResult? getCachedFirstPage();

  /// Fetches a specific page from the remote API and updates page-1 cache when `page == 1`.
  Future<BreedsPage> fetchBreedsPage({
    required int page,
    int limit = defaultPageSize,
    CancelToken? cancelToken,
  });

  /// Explicitly invalidates cached breeds (e.g., on forced Pull-to-Refresh).
  Future<void> invalidateCache();

  /// Resolves a breed by name from memory, local cache, or remote API (for Deep Links).
  Future<Breed> findBreedByName(
    String name, {
    CancelToken? cancelToken,
  });

  /// Fetches a random cat fact from `/fact`.
  Future<CatFact> fetchRandomFact({
    CancelToken? cancelToken,
  });
}
