import 'package:characters/characters.dart';
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

  static final RegExp _nonWordChars = RegExp(
    r'[^\p{L}\p{M}\p{N}\s]+',
    unicode: true,
  );
  static final RegExp _leadingMarks = RegExp(r'^\p{M}+', unicode: true);
  static final RegExp _hasLetterOrDigit = RegExp(
    r'[\p{L}\p{N}]',
    unicode: true,
  );

  /// Two-letter monogram for lightweight avatar rendering without image network cost.
  String get initials {
    final cleaned = breed.replaceAll(_nonWordChars, ' ').trim();
    if (cleaned.isEmpty) return '?';

    final parts = cleaned
        .split(RegExp(r'\s+'))
        .map((p) => p.replaceFirst(_leadingMarks, ''))
        .where((p) => p.isNotEmpty && _hasLetterOrDigit.hasMatch(p))
        .toList(growable: false);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return '${parts[0].characters.first}${parts[1].characters.first}'
        .toUpperCase();
  }

  static String _fallback(String value, String fallback) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }
}
