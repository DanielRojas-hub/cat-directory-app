import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/breed.dart';
import '../../domain/entities/cat_fact.dart';

part 'breed_detail_state.freezed.dart';

enum BreedDetailStatus { initial, loading, loaded, failure }

enum CatFactStatus { initial, loading, loaded, failure }

@freezed
abstract class BreedDetailState with _$BreedDetailState {
  const factory BreedDetailState({
    @Default(BreedDetailStatus.initial) BreedDetailStatus breedStatus,
    Breed? breed,
    String? breedErrorMessage,
    @Default(CatFactStatus.initial) CatFactStatus factStatus,
    CatFact? fact,
    String? factErrorMessage,
  }) = _BreedDetailState;
}
