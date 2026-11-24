import 'package:freezed_annotation/freezed_annotation.dart';

part 'breed.freezed.dart';

@freezed
abstract class Breed with _$Breed {
  const Breed._();

  const factory Breed({
    required String breed,
    required String country,
    required String origin,
    required String coat,
    required String pattern,
  }) = _Breed;

  String get displayCountry => _fallback(country, 'Origen desconocido');
  String get displayOrigin => _fallback(origin, 'No especificado');
  String get displayCoat => _fallback(coat, 'No especificado');
  String get displayPattern => _fallback(pattern, 'No especificado');

  /// URL-safe slug used in `/breed/:name` parameterized routes.
  String get routeSlug => Uri.encodeComponent(breed);

  /// Two-letter monogram for lightweight avatar rendering without image network cost.
  String get initials {
    final parts = breed
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  static String _fallback(String value, String fallback) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }
}
