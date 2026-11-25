import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/breed.dart';
import '../../domain/repositories/breeds_repository.dart';
import 'breed_detail_state.dart';

/// Cubit managing breed details (including cold-start Deep Link resolution)
/// and an independent lifecycle for the random cat fact endpoint (`/fact`).
final class BreedDetailCubit extends Cubit<BreedDetailState> {
  BreedDetailCubit({required this._repository})
      : super(const BreedDetailState());

  final BreedsRepository _repository;

  /// Loads breed details (instantly when [initialBreed] is provided, or via
  /// repository lookup for deep-linked routes) alongside an independent `/fact` call.
  Future<void> load({
    required String breedName,
    Breed? initialBreed,
  }) async {
    unawaited(loadRandomFact());

    if (initialBreed != null) {
      emit(
        state.copyWith(
          breedStatus: BreedDetailStatus.loaded,
          breed: initialBreed,
          breedErrorMessage: null,
        ),
      );
      return;
    }

    await _resolveBreedByName(breedName);
  }

  /// Retries resolving the breed when a deep-link lookup fails.
  Future<void> retryBreedLookup(String breedName) {
    return _resolveBreedByName(breedName);
  }

  Future<void> _resolveBreedByName(String breedName) async {
    emit(
      state.copyWith(
        breedStatus: BreedDetailStatus.loading,
        breedErrorMessage: null,
      ),
    );

    try {
      final breed = await _repository.findBreedByName(breedName);
      if (isClosed) return;
      emit(
        state.copyWith(
          breedStatus: BreedDetailStatus.loaded,
          breed: breed,
          breedErrorMessage: null,
        ),
      );
    } on AppFailure catch (failure) {
      if (isClosed) return;
      emit(
        state.copyWith(
          breedStatus: BreedDetailStatus.failure,
          breedErrorMessage: failure.message,
        ),
      );
    } on Object {
      if (isClosed) return;
      emit(
        state.copyWith(
          breedStatus: BreedDetailStatus.failure,
          breedErrorMessage: const UnknownFailure().message,
        ),
      );
    }
  }

  /// Fetches a random cat fact independently from the breed details state.
  Future<void> loadRandomFact() async {
    if (state.factStatus == CatFactStatus.loading) {
      return;
    }

    emit(
      state.copyWith(
        factStatus: CatFactStatus.loading,
        factErrorMessage: null,
      ),
    );

    try {
      final fact = await _repository.fetchRandomFact();
      if (isClosed) return;
      emit(
        state.copyWith(
          factStatus: CatFactStatus.loaded,
          fact: fact,
          factErrorMessage: null,
        ),
      );
    } on AppFailure catch (failure) {
      if (isClosed) return;
      emit(
        state.copyWith(
          factStatus: CatFactStatus.failure,
          factErrorMessage: failure.message,
        ),
      );
    } on Object {
      if (isClosed) return;
      emit(
        state.copyWith(
          factStatus: CatFactStatus.failure,
          factErrorMessage: const UnknownFailure().message,
        ),
      );
    }
  }
}
