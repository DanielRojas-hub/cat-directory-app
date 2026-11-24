import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/cat_fact.dart';

part 'cat_fact_model.freezed.dart';
part 'cat_fact_model.g.dart';

@freezed
abstract class CatFactModel with _$CatFactModel {
  const CatFactModel._();

  const factory CatFactModel({
    @Default('') String fact,
    @Default(0) int length,
  }) = _CatFactModel;

  factory CatFactModel.fromJson(Map<String, dynamic> json) =>
      _$CatFactModelFromJson(json);

  CatFact toEntity() => CatFact(
        fact: fact,
        length: length,
      );
}
