import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';

import '../errors/app_failure.dart';
import 'connectivity_monitor.dart';

/// Dio interceptor that performs fast-fail offline detection, enforces a total
/// per-request retry deadline, respects HTTP 429 `Retry-After` headers, honors
/// [CancelToken] cancellation during backoff delays, and retries transient
/// network/server errors using exponential backoff with jitter.
final class ExponentialBackoffInterceptor extends Interceptor {
  ExponentialBackoffInterceptor({
    required this.dio,
    required this.connectivityMonitor,
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 500),
    this.maxJitter = const Duration(milliseconds: 200),
    this.totalDeadline = const Duration(seconds: 16),
    Future<void> Function(Duration delay)? delayFn,
    DateTime Function()? clock,
    Random? random,
  })  : _delayFn = delayFn ?? Future<void>.delayed,
        _clock = clock ?? DateTime.now,
        _random = random ?? Random();

  static const String _attemptKey = 'retry_attempt';
  static const String _startedAtKey = 'retry_started_at';

  final Dio dio;
  final ConnectivityMonitor connectivityMonitor;
  final int maxRetries;
  final Duration baseDelay;
  final Duration maxJitter;
  final Duration? totalDeadline;
  final Future<void> Function(Duration delay) _delayFn;
  final DateTime Function() _clock;
  final Random _random;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final cancelToken = options.cancelToken;
    if (cancelToken?.isCancelled ?? false) {
      handler.reject(
        DioException.requestCancelled(
          requestOptions: options,
          reason: cancelToken?.cancelError?.error,
        ),
        true,
      );
      return;
    }

    options.extra.putIfAbsent(_startedAtKey, () => _clock().toUtc());

    final isConnected = await connectivityMonitor.hasConnection;
    if (cancelToken?.isCancelled ?? false) {
      handler.reject(
        DioException.requestCancelled(
          requestOptions: options,
          reason: cancelToken?.cancelError?.error,
        ),
        true,
      );
      return;
    }

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
    final cancelToken = err.requestOptions.cancelToken;
    if (cancelToken?.isCancelled ?? false) {
      handler.next(err);
      return;
    }

    final attempt = (err.requestOptions.extra[_attemptKey] as int?) ?? 0;

    if (attempt >= maxRetries || !_isRetryable(err)) {
      handler.next(err);
      return;
    }

    // Short-circuit if the device has lost network connectivity completely.
    final isConnected = await connectivityMonitor.hasConnection;
    if (cancelToken?.isCancelled ?? false) {
      handler.next(
        DioException.requestCancelled(
          requestOptions: err.requestOptions,
          reason: cancelToken?.cancelError?.error,
        ),
      );
      return;
    }
    if (!isConnected) {
      handler.next(err);
      return;
    }

    final delay = _resolveRetryDelay(err, attempt);
    final startedAt = err.requestOptions.extra[_startedAtKey] as DateTime?;
    final deadline = totalDeadline;

    if (startedAt != null && deadline != null) {
      final remaining = deadline - _elapsedSince(startedAt);
      if (remaining <= Duration.zero || delay >= remaining) {
        handler.next(err);
        return;
      }
    }

    if (delay > Duration.zero) {
      await _waitForDelayOrCancel(delay, cancelToken);
      if (cancelToken?.isCancelled ?? false) {
        handler.next(
          DioException.requestCancelled(
            requestOptions: err.requestOptions,
            reason: cancelToken?.cancelError?.error,
          ),
        );
        return;
      }
    }

    Duration? remainingAfterDelay;
    if (startedAt != null && deadline != null) {
      final remaining = deadline - _elapsedSince(startedAt);
      if (remaining <= Duration.zero) {
        handler.next(err);
        return;
      }
      remainingAfterDelay = remaining;
    }

    final retryOptions = err.requestOptions.copyWith(
      connectTimeout: _clampTimeout(
        err.requestOptions.connectTimeout,
        remainingAfterDelay,
      ),
      receiveTimeout: _clampTimeout(
        err.requestOptions.receiveTimeout,
        remainingAfterDelay,
      ),
      sendTimeout: _clampTimeout(
        err.requestOptions.sendTimeout,
        remainingAfterDelay,
      ),
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

  /// Parses an HTTP `Retry-After` header (non-negative seconds or HTTP-date).
  Duration? parseRetryAfter(String? headerValue) {
    if (headerValue == null) return null;
    final trimmed = headerValue.trim();
    if (trimmed.isEmpty) return null;

    final seconds = int.tryParse(trimmed);
    if (seconds != null) {
      return seconds >= 0 ? Duration(seconds: seconds) : null;
    }

    try {
      final targetDate = HttpDate.parse(trimmed).toUtc();
      final delta = targetDate.difference(_clock().toUtc());
      return delta.isNegative ? Duration.zero : delta;
    } on FormatException {
      return null;
    } on HttpException {
      return null;
    }
  }

  Duration _resolveRetryDelay(DioException err, int attempt) {
    final backoffDelay = computeDelay(attempt);
    if (err.type == DioExceptionType.badResponse &&
        err.response?.statusCode == 429) {
      final retryAfter = parseRetryAfter(
        err.response?.headers.value('retry-after'),
      );
      if (retryAfter != null && retryAfter > backoffDelay) {
        return retryAfter;
      }
    }
    return backoffDelay;
  }

  Duration _elapsedSince(DateTime startedAt) {
    final elapsed = _clock().toUtc().difference(startedAt.toUtc());
    return elapsed.isNegative ? Duration.zero : elapsed;
  }

  Duration? _clampTimeout(Duration? configured, Duration? remaining) {
    if (configured == null || remaining == null) return configured;
    return configured <= remaining ? configured : remaining;
  }

  Future<void> _waitForDelayOrCancel(
    Duration delay,
    CancelToken? cancelToken,
  ) async {
    if (cancelToken == null) {
      await _delayFn(delay);
      return;
    }
    final delayFuture = _delayFn(delay);
    delayFuture.ignore();
    await Future.any<void>([
      delayFuture,
      cancelToken.whenCancel.then((_) {}),
    ]);
  }

  bool _isRetryable(DioException err) {
    if (err.type == DioExceptionType.badCertificate) {
      return false;
    }
    if (err.type == DioExceptionType.unknown) {
      return err.error is IOException;
    }
    if (err.type == DioExceptionType.badResponse &&
        err.response?.statusCode == null) {
      return false;
    }
    return AppFailure.fromDioException(err).isRetryable;
  }
}
