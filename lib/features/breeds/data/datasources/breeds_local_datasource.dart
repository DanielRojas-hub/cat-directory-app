import '../../../../core/storage/cache_envelope.dart';
import '../models/breeds_page_model.dart';

/// Local persistence data source storing page 1 of breeds with explicit TTL.
abstract interface class BreedsLocalDataSource {
  CacheEnvelope<BreedsPageModel>? readFirstPage();

  Future<void> saveFirstPage(BreedsPageModel page);

  Future<void> invalidate();
}

final class BreedsLocalDataSourceImpl implements BreedsLocalDataSource {
  const BreedsLocalDataSourceImpl(
    this._cacheStore, {
    this.ttl = defaultTtl,
  });

  static const String cacheKey = 'cat_breeds_first_page_v1';
  static const Duration defaultTtl = Duration(minutes: 10);

  final CacheStore _cacheStore;
  final Duration ttl;

  @override
  CacheEnvelope<BreedsPageModel>? readFirstPage() {
    final envelope = _cacheStore.readJson(cacheKey);
    if (envelope == null) {
      return null;
    }

    try {
      final model = BreedsPageModel.fromJson(envelope.data);
      return CacheEnvelope<BreedsPageModel>(
        data: model,
        cachedAt: envelope.cachedAt,
        ttl: envelope.ttl,
      );
    } on Object {
      // Self-heal schema changes or malformed persisted models.
      _cacheStore.invalidate(cacheKey).ignore();
      return null;
    }
  }

  @override
  Future<void> saveFirstPage(BreedsPageModel page) {
    return _cacheStore.writeJson(
      key: cacheKey,
      payload: page.toJson(),
      ttl: ttl,
    );
  }

  @override
  Future<void> invalidate() {
    return _cacheStore.invalidate(cacheKey);
  }
}
