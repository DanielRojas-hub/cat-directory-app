import 'package:dio/dio.dart';

import '../../../../core/errors/app_failure.dart';
import '../models/breeds_page_model.dart';
import '../models/cat_fact_model.dart';

/// Remote data source consuming the public Catfact Ninja REST API.
abstract interface class BreedsRemoteDataSource {
  Future<BreedsPageModel> fetchBreedsPage({
    required int page,
    required int limit,
    CancelToken? cancelToken,
  });

  Future<CatFactModel> fetchRandomFact({
    CancelToken? cancelToken,
  });
}

final class BreedsRemoteDataSourceImpl implements BreedsRemoteDataSource {
  const BreedsRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<BreedsPageModel> fetchBreedsPage({
    required int page,
    required int limit,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = cancelToken != null
          ? await _dio.get<Map<String, dynamic>>(
              '/breeds',
              queryParameters: {
                'page': page,
                'limit': limit,
              },
              cancelToken: cancelToken,
            )
          : await _dio.get<Map<String, dynamic>>(
              '/breeds',
              queryParameters: {
                'page': page,
                'limit': limit,
              },
            );
      final data = response.data;
      if (data == null) {
        throw const ServerFailure(
          message: 'La API devolvió una respuesta vacía.',
        );
      }
      return BreedsPageModel.fromJson(data);
    } on DioException catch (e) {
      throw AppFailure.fromDioException(e);
    } on AppFailure {
      rethrow;
    } on Object catch (e) {
      throw UnknownFailure(
        message: 'No pudimos procesar el listado de razas.',
        cause: e,
      );
    }
  }

  @override
  Future<CatFactModel> fetchRandomFact({
    CancelToken? cancelToken,
  }) async {
    try {
      final response = cancelToken != null
          ? await _dio.get<Map<String, dynamic>>(
              '/fact',
              cancelToken: cancelToken,
            )
          : await _dio.get<Map<String, dynamic>>('/fact');
      final data = response.data;
      if (data == null) {
        throw const ServerFailure(
          message: 'La API no devolvió un dato curioso.',
        );
      }
      final model = CatFactModel.fromJson(data);
      if (model.fact.trim().isEmpty) {
        throw const ServerFailure(
          message: 'La API devolvió un dato curioso vacío.',
        );
      }
      return model;
    } on DioException catch (e) {
      throw AppFailure.fromDioException(e);
    } on AppFailure {
      rethrow;
    } on Object catch (e) {
      throw UnknownFailure(
        message: 'No pudimos procesar el dato curioso.',
        cause: e,
      );
    }
  }
}
