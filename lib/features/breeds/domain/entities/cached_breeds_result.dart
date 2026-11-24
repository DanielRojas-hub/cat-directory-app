import 'breeds_page.dart';

/// Domain representation of a cached breeds page paired with explicit TTL state.
final class CachedBreedsResult {
  const CachedBreedsResult({
    required this.page,
    required this.cachedAt,
    required this.isExpired,
  });

  final BreedsPage page;
  final DateTime cachedAt;
  final bool isExpired;
}
