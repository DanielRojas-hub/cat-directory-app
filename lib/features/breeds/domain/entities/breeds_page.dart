import 'package:freezed_annotation/freezed_annotation.dart';

import 'breed.dart';

part 'breeds_page.freezed.dart';

@freezed
abstract class BreedsPage with _$BreedsPage {
  const BreedsPage._();

  const factory BreedsPage({
    required int currentPage,
    required int lastPage,
    required int total,
    required List<Breed> items,
  }) = _BreedsPage;

  bool get hasMore => currentPage < lastPage;
}
