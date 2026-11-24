import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/breeds_page.dart';
import 'breed_model.dart';

part 'breeds_page_model.freezed.dart';
part 'breeds_page_model.g.dart';

@freezed
abstract class BreedsPageModel with _$BreedsPageModel {
  const BreedsPageModel._();

  const factory BreedsPageModel({
    @JsonKey(name: 'current_page') @Default(1) int currentPage,
    @JsonKey(name: 'last_page') @Default(1) int lastPage,
    @Default(0) int total,
    @Default(<BreedModel>[]) List<BreedModel> data,
  }) = _BreedsPageModel;

  factory BreedsPageModel.fromJson(Map<String, dynamic> json) =>
      _$BreedsPageModelFromJson(json);

  BreedsPage toEntity() => BreedsPage(
        currentPage: currentPage,
        lastPage: lastPage,
        total: total,
        items: data.map((item) => item.toEntity()).toList(growable: false),
      );
}
