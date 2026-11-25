import 'package:dio/dio.dart';

/// Base sealed hierarchy for typed domain/application failures.
sealed class AppFailure implements Exception {
  const AppFailure({
    required this.message,
    this.isRetryable = false,
    this.cause,
  });

  final String message;
  final bool isRetryable;
  final Object? cause;

  /// Returns `true` when this failure resulted from an explicit request cancellation.
  bool get isCancellation =>
      cause is DioException &&
      (cause! as DioException).type == DioExceptionType.cancel;

  /// Maps a [DioException] into a user-friendly, typed [AppFailure].
  factory AppFailure.fromDioException(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionError:
        return NetworkFailure(cause: exception);
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return TimeoutFailure(cause: exception);
      case DioExceptionType.badResponse:
        final statusCode = exception.response?.statusCode;
        if (statusCode == 404) {
          return NotFoundFailure(cause: exception);
        }
        if (statusCode == 429) {
          return ServerFailure(
            statusCode: statusCode,
            message:
                'Demasiadas solicitudes al servidor. Intenta nuevamente en unos segundos.',
            cause: exception,
          );
        }
        return ServerFailure(
          statusCode: statusCode,
          cause: exception,
        );
      case DioExceptionType.cancel:
        return UnknownFailure(
          message: 'La solicitud fue cancelada.',
          cause: exception,
        );
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return NetworkFailure(
          message:
              'Ocurrió un problema de red inesperado. Verifica tu conexión.',
          cause: exception,
        );
    }
  }

  @override
  String toString() => '$runtimeType(message: $message)';
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure({
    super.message = 'Sin conexión a internet. Verifica tu red e intenta de nuevo.',
    super.cause,
  }) : super(isRetryable: true);
}

final class TimeoutFailure extends AppFailure {
  const TimeoutFailure({
    super.message =
        'La conexión tardó demasiado en responder. Intenta nuevamente.',
    super.cause,
  }) : super(isRetryable: true);
}

final class ServerFailure extends AppFailure {
  const ServerFailure({
    this.statusCode,
    super.message =
        'El servicio de Catfact Ninja no está disponible en este momento.',
    super.cause,
  }) : super(
          isRetryable:
              statusCode == null || statusCode == 429 || statusCode >= 500,
        );

  final int? statusCode;
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure({
    super.message = 'No encontramos la información solicitada.',
    super.cause,
  }) : super(isRetryable: false);
}

final class CacheFailure extends AppFailure {
  const CacheFailure({
    super.message = 'No se pudo leer la información guardada localmente.',
    super.cause,
  }) : super(isRetryable: false);
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure({
    super.message = 'Ocurrió un error inesperado. Intenta de nuevo.',
    super.cause,
  }) : super(isRetryable: false);
}
