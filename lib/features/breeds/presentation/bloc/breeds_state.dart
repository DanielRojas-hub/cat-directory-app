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

  /// Filters in-memory breeds by name without mutating the loaded list.
  List<Breed> get filteredBreeds {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return breeds;
    }
    return breeds
        .where((item) => item.breed.toLowerCase().contains(query))
        .toList(growable: false);
  }
}
