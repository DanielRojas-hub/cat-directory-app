import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';

import 'connectivity_monitor.dart';

/// Dio interceptor that performs fast-fail offline detection and retries
/// transient network/server errors using exponential backoff with jitter.
final class ExponentialBackoffInterceptor extends Interceptor {
  ExponentialBackoffInterceptor({
    required this.dio,
    required this.connectivityMonitor,
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 500),
    this.maxJitter = const Duration(milliseconds: 200),
    Future<void> Function(Duration delay)? delayFn,
    Random? random,
  })  : _delayFn = delayFn ?? Future<void>.delayed,
        _random = random ?? Random();

  static const String _attemptKey = 'retry_attempt';

  final Dio dio;
  final ConnectivityMonitor connectivityMonitor;
  final int maxRetries;
  final Duration baseDelay;
  final Duration maxJitter;
  final Future<void> Function(Duration delay) _delayFn;
  final Random _random;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final isConnected = await connectivityMonitor.hasConnection;
    if (!isConnected) {
      handler.reject(
        DioException.connectionError(
          requestOptions: options,
          reason: 'No active network interface detected.',
        ),
        true,
      );
      return;
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = (err.requestOptions.extra[_attemptKey] as int?) ?? 0;

    if (attempt >= maxRetries || !_isRetryable(err)) {
      handler.next(err);
      return;
    }

    // Short-circuit if the device has lost network connectivity completely.
    final isConnected = await connectivityMonitor.hasConnection;
    if (!isConnected) {
      handler.next(err);
      return;
    }

    final delay = computeDelay(attempt);
    await _delayFn(delay);

    final retryOptions = err.requestOptions.copyWith(
      extra: {
        ...err.requestOptions.extra,
        _attemptKey: attempt + 1,
      },
    );

    try {
      final response = await dio.fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// Computes `baseDelay * 2^attempt + randomJitter` for a zero-based [attempt].
  Duration computeDelay(int attempt) {
    final exponentialMs = baseDelay.inMilliseconds * (1 << attempt);
    final jitterMs = maxJitter.inMilliseconds > 0
        ? _random.nextInt(maxJitter.inMilliseconds + 1)
        : 0;
    return Duration(milliseconds: exponentialMs + jitterMs);
  }

  bool _isRetryable(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode ?? 0;
        return statusCode == 429 || statusCode >= 500;
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
        return false;
      case DioExceptionType.unknown:
        return err.error is IOException;
    }
  }
}
