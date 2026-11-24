import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/breed.dart';

part 'breed_model.freezed.dart';
part 'breed_model.g.dart';

@freezed
abstract class BreedModel with _$BreedModel {
  const BreedModel._();

  const factory BreedModel({
    @Default('') String breed,
    @Default('') String country,
    @Default('') String origin,
    @Default('') String coat,
    @Default('') String pattern,
  }) = _BreedModel;

  factory BreedModel.fromJson(Map<String, dynamic> json) =>
      _$BreedModelFromJson(json);

  factory BreedModel.fromEntity(Breed entity) => BreedModel(
        breed: entity.breed,
        country: entity.country,
        origin: entity.origin,
        coat: entity.coat,
        pattern: entity.pattern,
      );

  Breed toEntity() => Breed(
        breed: breed,
        country: country,
        origin: origin,
        coat: coat,
        pattern: pattern,
      );
}
