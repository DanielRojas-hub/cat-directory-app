import 'dart:io';

import 'package:cat_directory_app/core/errors/app_failure.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final requestOptions = RequestOptions(path: '/breeds');

  DioException badResponse(int? statusCode) {
    return DioException(
      requestOptions: requestOptions,
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(
        requestOptions: requestOptions,
        statusCode: statusCode,
      ),
    );
  }

  group('ServerFailure.isRetryable', () {
    test('is false for 4xx client errors other than 429', () {
      for (final code in const [400, 401, 403, 404, 422]) {
        final failure = ServerFailure(statusCode: code);
        expect(
          failure.isRetryable,
          isFalse,
          reason: 'HTTP $code should not be retryable',
        );
      }
    });

    test('is true for 429, 5xx and null statusCode', () {
      for (final code in const <int?>[429, 500, 502, 503, 504, null]) {
        final failure = ServerFailure(statusCode: code);
        expect(
          failure.isRetryable,
          isTrue,
          reason: 'HTTP $code should be retryable',
        );
      }
    });
  });

  group('AppFailure.fromDioException', () {
    test('maps connectionError to retryable NetworkFailure', () {
      final exception = DioException.connectionError(
        requestOptions: requestOptions,
        reason: 'Offline',
      );

      final failure = AppFailure.fromDioException(exception);

      expect(failure, isA<NetworkFailure>());
      expect(failure.isRetryable, isTrue);
      expect(failure.cause, same(exception));
    });

    test('maps all timeout types to retryable TimeoutFailure', () {
      for (final type in const [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.transformTimeout,
      ]) {
        final exception = DioException(
          requestOptions: requestOptions,
          type: type,
        );

        final failure = AppFailure.fromDioException(exception);

        expect(failure, isA<TimeoutFailure>(), reason: 'Failed for $type');
        expect(failure.isRetryable, isTrue);
        expect(failure.cause, same(exception));
      }
    });

    test('maps badResponse 404 to non-retryable NotFoundFailure', () {
      final exception = badResponse(404);

      final failure = AppFailure.fromDioException(exception);

      expect(failure, isA<NotFoundFailure>());
      expect(failure.isRetryable, isFalse);
      expect(failure.cause, same(exception));
    });

    test('maps badResponse 4xx (400, 401, 403, 422) to non-retryable ServerFailure',
        () {
      for (final code in const [400, 401, 403, 422]) {
        final exception = badResponse(code);
        final failure = AppFailure.fromDioException(exception);

        expect(failure, isA<ServerFailure>(), reason: 'Failed for HTTP $code');
        final serverFailure = failure as ServerFailure;
        expect(serverFailure.statusCode, code);
        expect(serverFailure.isRetryable, isFalse);
        expect(serverFailure.cause, same(exception));
      }
    });

    test('maps badResponse 429 to retryable ServerFailure with rate-limit message',
        () {
      final exception = badResponse(429);

      final failure = AppFailure.fromDioException(exception);

      expect(failure, isA<ServerFailure>());
      final serverFailure = failure as ServerFailure;
      expect(serverFailure.statusCode, 429);
      expect(serverFailure.isRetryable, isTrue);
      expect(serverFailure.message, contains('Demasiadas solicitudes'));
    });

    test('maps badResponse 5xx and null statusCode to retryable ServerFailure',
        () {
      for (final code in const <int?>[500, 502, 503, null]) {
        final exception = badResponse(code);
        final failure = AppFailure.fromDioException(exception);

        expect(failure, isA<ServerFailure>(), reason: 'Failed for HTTP $code');
        final serverFailure = failure as ServerFailure;
        expect(serverFailure.statusCode, code);
        expect(serverFailure.isRetryable, isTrue);
      }
    });

    test('maps cancel to non-retryable UnknownFailure', () {
      final exception = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.cancel,
      );

      final failure = AppFailure.fromDioException(exception);

      expect(failure, isA<UnknownFailure>());
      expect(failure.isRetryable, isFalse);
      expect(failure.isCancellation, isTrue);
      expect(failure.message, contains('cancelada'));
      expect(const NetworkFailure().isCancellation, isFalse);
    });

    test('maps badCertificate and unknown (with or without SocketException) to NetworkFailure',
        () {
      final cases = [
        DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.badCertificate,
        ),
        DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.unknown,
          error: const SocketException('Connection reset by peer'),
        ),
        DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.unknown,
        ),
      ];

      for (final exception in cases) {
        final failure = AppFailure.fromDioException(exception);
        expect(failure, isA<NetworkFailure>());
        expect(failure.isRetryable, isTrue);
        expect(failure.cause, same(exception));
      }
    });
  });
}
