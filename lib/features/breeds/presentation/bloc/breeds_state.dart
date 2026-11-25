import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/breed.dart';

part 'breeds_state.freezed.dart';

enum BreedsStatus { initial, loading, loaded, failure }

enum BreedsNoticeKind { info, warning, error }

@freezed
abstract class BreedsNotice with _$BreedsNotice {
  const factory BreedsNotice({
    required String message,
    required BreedsNoticeKind kind,
    required int id,
  }) = _BreedsNotice;
}

@freezed
abstract class BreedsState with _$BreedsState {
  const BreedsState._();

  const factory BreedsState({
    @Default(BreedsStatus.initial) BreedsStatus status,
    @Default(<Breed>[]) List<Breed> breeds,
    @Default('') String searchQuery,
    @Default(0) int currentPage,
    @Default(1) int lastPage,
    @Default(0) int total,
    @Default(false) bool isLoadingMore,
    @Default(false) bool isRevalidating,
    @Default(false) bool isFromCache,
    @Default(true) bool isOnline,
    DateTime? lastSyncedAt,
    String? errorMessage,
    String? paginationErrorMessage,
    BreedsNotice? notice,
  }) = _BreedsState;

  bool get hasMore => currentPage < lastPage;

  bool get isSearching => searchQuery.trim().isNotEmpty;

  static final RegExp _combiningMarks = RegExp(r'\p{Mn}+', unicode: true);

  static const Map<String, String> _diacriticMap = <String, String>{
    'æ': 'ae',
    'œ': 'oe',
    'ß': 'ss',
    'ø': 'o',
    'đ': 'd',
    'ð': 'd',
    'ł': 'l',
    'þ': 'th',
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'ã': 'a',
    'å': 'a',
    'ā': 'a',
    'ă': 'a',
    'ą': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'ē': 'e',
    'ĕ': 'e',
    'ė': 'e',
    'ę': 'e',
    'ě': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ĩ': 'i',
    'ī': 'i',
    'ĭ': 'i',
    'į': 'i',
    'ı': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'ö': 'o',
    'õ': 'o',
    'ō': 'o',
    'ŏ': 'o',
    'ő': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ũ': 'u',
    'ū': 'u',
    'ŭ': 'u',
    'ů': 'u',
    'ű': 'u',
    'ų': 'u',
    'ý': 'y',
    'ÿ': 'y',
    'ŷ': 'y',
    'ñ': 'n',
    'ń': 'n',
    'ņ': 'n',
    'ň': 'n',
    'ç': 'c',
    'ć': 'c',
    'ĉ': 'c',
    'ċ': 'c',
    'č': 'c',
    'ś': 's',
    'ŝ': 's',
    'ş': 's',
    'š': 's',
    'ź': 'z',
    'ż': 'z',
    'ž': 'z',
    'ř': 'r',
    'ŕ': 'r',
    'ŗ': 'r',
    'ť': 't',
    'ţ': 't',
    'ŧ': 't',
    'ğ': 'g',
    'ĝ': 'g',
    'ġ': 'g',
    'ģ': 'g',
    'ĥ': 'h',
    'ħ': 'h',
    'ĵ': 'j',
    'ķ': 'k',
    'ŵ': 'w',
  };

  static String _normalizeSearchText(String input) {
    final trimmed = input.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return '';
    }
    if (!trimmed.codeUnits.any((c) => c > 0x7F)) {
      return trimmed;
    }
    final withoutMarks = trimmed.replaceAll(_combiningMarks, '');
    final buffer = StringBuffer();
    for (final rune in withoutMarks.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_diacriticMap[char] ?? char);
    }
    return buffer.toString();
  }

  /// Filters in-memory breeds by name without mutating the loaded list,
  /// normalizing basic diacritics and ligatures (e.g. `æ` -> `ae`).
  List<Breed> get filteredBreeds {
    final query = _normalizeSearchText(searchQuery);
    if (query.isEmpty) {
      return breeds;
    }
    return breeds
        .where((item) => _normalizeSearchText(item.breed).contains(query))
        .toList(growable: false);
  }
}
