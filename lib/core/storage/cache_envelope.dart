import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Immutable wrapper pairing cached data with explicit expiration metadata (TTL).
final class CacheEnvelope<T> {
  const CacheEnvelope({
    required this.data,
    required this.cachedAt,
    required this.ttl,
  });

  final T data;
  final DateTime cachedAt;
  final Duration ttl;

  /// Returns `true` when the elapsed time since [cachedAt] meets or exceeds [ttl].
  bool isExpired([DateTime? now]) {
    return age(now) >= ttl;
  }

  /// Elapsed duration since this entry was written.
  Duration age([DateTime? now]) {
    final reference = (now ?? DateTime.now()).toUtc();
    final elapsed = reference.difference(cachedAt.toUtc());
    return elapsed.isNegative ? Duration.zero : elapsed;
  }
}

/// Key-value persistent cache contract with explicit TTL and invalidation.
abstract interface class CacheStore {
  Future<void> writeJson({
    required String key,
    required Map<String, dynamic> payload,
    required Duration ttl,
    DateTime? now,
  });

  CacheEnvelope<Map<String, dynamic>>? readJson(String key);

  Future<void> invalidate(String key);
}

final class SharedPreferencesCacheStore implements CacheStore {
  SharedPreferencesCacheStore(this._preferences);

  final SharedPreferences _preferences;

  static const String _cachedAtField = 'cached_at';
  static const String _ttlSecondsField = 'ttl_seconds';
  static const String _payloadField = 'payload';

  @override
  Future<void> writeJson({
    required String key,
    required Map<String, dynamic> payload,
    required Duration ttl,
    DateTime? now,
  }) async {
    final envelope = <String, dynamic>{
      _cachedAtField: (now ?? DateTime.now()).toUtc().toIso8601String(),
      _ttlSecondsField: ttl.inSeconds,
      _payloadField: payload,
    };
    await _preferences.setString(key, jsonEncode(envelope));
  }

  @override
  CacheEnvelope<Map<String, dynamic>>? readJson(String key) {
    final raw = _preferences.getString(key);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(decoded[_cachedAtField] as String).toUtc();
      final ttlSeconds = decoded[_ttlSecondsField] as int;
      final payload = decoded[_payloadField] as Map<String, dynamic>;

      return CacheEnvelope<Map<String, dynamic>>(
        data: payload,
        cachedAt: cachedAt,
        ttl: Duration(seconds: ttlSeconds),
      );
    } on Object {
      // Self-heal corrupted cache entries so they never block cold startup.
      _preferences.remove(key).ignore();
      return null;
    }
  }

  @override
  Future<void> invalidate(String key) async {
    await _preferences.remove(key);
  }
}
