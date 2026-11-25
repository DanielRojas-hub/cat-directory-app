import 'dart:async';

import 'package:dio/dio.dart';
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
  CancelToken? _breedLookupCancelToken;
  CancelToken? _factCancelToken;

  void _cancelToken(CancelToken? token, String reason) {
    if (token != null && !token.isCancelled) {
      token.cancel(reason);
    }
  }

  /// Loads breed details (instantly when [initialBreed] is provided, or via
  /// repository lookup for deep-linked routes) alongside an independent `/fact` call.
  Future<void> load({
    required String breedName,
    Breed? initialBreed,
  }) async {
    if (isClosed) return;
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
    if (isClosed) return;
    _cancelToken(_breedLookupCancelToken, 'Superseded by new breed lookup');
    final cancelToken = CancelToken();
    _breedLookupCancelToken = cancelToken;

    emit(
      state.copyWith(
        breedStatus: BreedDetailStatus.loading,
        breedErrorMessage: null,
      ),
    );

    try {
      final breed = await _repository.findBreedByName(
        breedName,
        cancelToken: cancelToken,
      );
      if (isClosed || cancelToken.isCancelled) return;
      emit(
        state.copyWith(
          breedStatus: BreedDetailStatus.loaded,
          breed: breed,
          breedErrorMessage: null,
        ),
      );
    } on AppFailure catch (failure) {
      if (isClosed || cancelToken.isCancelled || failure.isCancellation) return;
      emit(
        state.copyWith(
          breedStatus: BreedDetailStatus.failure,
          breedErrorMessage: failure.message,
        ),
      );
    } on Object {
      if (isClosed || cancelToken.isCancelled) return;
      emit(
        state.copyWith(
          breedStatus: BreedDetailStatus.failure,
          breedErrorMessage: const UnknownFailure().message,
        ),
      );
    } finally {
      if (identical(_breedLookupCancelToken, cancelToken)) {
        _breedLookupCancelToken = null;
      }
    }
  }

  /// Fetches a random cat fact independently from the breed details state.
  Future<void> loadRandomFact() async {
    if (isClosed || state.factStatus == CatFactStatus.loading) {
      return;
    }

    final cancelToken = CancelToken();
    _factCancelToken = cancelToken;

    emit(
      state.copyWith(
        factStatus: CatFactStatus.loading,
        factErrorMessage: null,
      ),
    );

    try {
      final fact = await _repository.fetchRandomFact(cancelToken: cancelToken);
      if (isClosed || cancelToken.isCancelled) return;
      emit(
        state.copyWith(
          factStatus: CatFactStatus.loaded,
          fact: fact,
          factErrorMessage: null,
        ),
      );
    } on AppFailure catch (failure) {
      if (isClosed || cancelToken.isCancelled || failure.isCancellation) return;
      emit(
        state.copyWith(
          factStatus: CatFactStatus.failure,
          factErrorMessage: failure.message,
        ),
      );
    } on Object {
      if (isClosed || cancelToken.isCancelled) return;
      emit(
        state.copyWith(
          factStatus: CatFactStatus.failure,
          factErrorMessage: const UnknownFailure().message,
        ),
      );
    } finally {
      if (identical(_factCancelToken, cancelToken)) {
        _factCancelToken = null;
      }
    }
  }

  @override
  Future<void> close() {
    _cancelToken(_breedLookupCancelToken, 'BreedDetailCubit closed');
    _breedLookupCancelToken = null;
    _cancelToken(_factCancelToken, 'BreedDetailCubit closed');
    _factCancelToken = null;
    return super.close();
  }
}
