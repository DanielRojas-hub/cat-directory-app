import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cat_directory_app/core/network/connectivity_monitor.dart';
import 'package:cat_directory_app/core/network/dio_client.dart';
import 'package:cat_directory_app/core/network/exponential_backoff_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockConnectivityMonitor extends Mock implements ConnectivityMonitor {}

/// Scripted [HttpClientAdapter] to simulate transient failures and recoveries.
class _ScriptedHttpAdapter implements HttpClientAdapter {
  _ScriptedHttpAdapter(this._responses);

  final List<Future<ResponseBody> Function(RequestOptions)> _responses;
  int callCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    final index = callCount < _responses.length
        ? callCount
        : _responses.length - 1;
    callCount++;
    return _responses[index](options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('ExponentialBackoffInterceptor', () {
    late _MockConnectivityMonitor connectivity;

    setUp(() {
      connectivity = _MockConnectivityMonitor();
      when(() => connectivity.hasConnection).thenAnswer((_) async => true);
    });

    test('retries transient 503 errors with exponential backoff and resolves',
        () async {
      final recordedDelays = <Duration>[];
      final adapter = _ScriptedHttpAdapter([
        (_) async => ResponseBody.fromString('Service Unavailable', 503),
        (_) async => ResponseBody.fromString('Service Unavailable', 503),
        (_) async => ResponseBody.fromString(
              jsonEncode({'fact': 'Recovered!', 'length': 10}),
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            ),
      ]);

      final dio = Dio(BaseOptions(baseUrl: 'https://catfact.ninja'))
        ..httpClientAdapter = adapter;

      dio.interceptors.add(
        ExponentialBackoffInterceptor(
          dio: dio,
          connectivityMonitor: connectivity,
          maxRetries: 3,
          baseDelay: const Duration(milliseconds: 500),
          maxJitter: Duration.zero,
          delayFn: (delay) async => recordedDelays.add(delay),
          random: Random(0),
        ),
      );

      final response = await dio.get<Map<String, dynamic>>('/fact');

      expect(response.statusCode, 200);
      expect(response.data?['fact'], 'Recovered!');
      expect(adapter.callCount, 3);
      expect(
        recordedDelays,
        [const Duration(milliseconds: 500), const Duration(milliseconds: 1000)],
      );
    });

    test('stops after maxRetries (3) and exposes error to caller', () async {
      final recordedDelays = <Duration>[];
      final adapter = _ScriptedHttpAdapter([
        (_) async => ResponseBody.fromString('Server Error', 500),
      ]);

      final dio = Dio(BaseOptions(baseUrl: 'https://catfact.ninja'))
        ..httpClientAdapter = adapter;

      dio.interceptors.add(
        ExponentialBackoffInterceptor(
          dio: dio,
          connectivityMonitor: connectivity,
          maxRetries: 3,
          baseDelay: const Duration(milliseconds: 500),
          maxJitter: Duration.zero,
          delayFn: (delay) async => recordedDelays.add(delay),
        ),
      );

      await expectLater(
        () => dio.get<Map<String, dynamic>>('/breeds'),
        throwsA(isA<DioException>()),
      );

      // 1 initial attempt + 3 retries = 4 total HTTP calls.
      expect(adapter.callCount, 4);
      expect(recordedDelays, [
        const Duration(milliseconds: 500),
        const Duration(milliseconds: 1000),
        const Duration(milliseconds: 2000),
      ]);
    });

    test('short-circuits immediately with zero retries when device is offline',
        () async {
      when(() => connectivity.hasConnection).thenAnswer((_) async => false);
      final recordedDelays = <Duration>[];
      final adapter = _ScriptedHttpAdapter([
        (_) async => ResponseBody.fromString('{}', 200),
      ]);

      final dio = Dio(BaseOptions(baseUrl: 'https://catfact.ninja'))
        ..httpClientAdapter = adapter;

      dio.interceptors.add(
        ExponentialBackoffInterceptor(
          dio: dio,
          connectivityMonitor: connectivity,
          delayFn: (delay) async => recordedDelays.add(delay),
        ),
      );

      await expectLater(
        () => dio.get<Map<String, dynamic>>('/breeds'),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.connectionError,
          ),
        ),
      );

      expect(adapter.callCount, 0);
      expect(recordedDelays, isEmpty);
    });

    test(
        'retries DioExceptionType.unknown wrapping SocketException (IOException) and resolves',
        () async {
      final recordedDelays = <Duration>[];
      final adapter = _ScriptedHttpAdapter([
        (_) async => throw const SocketException('Connection reset by peer'),
        (_) async => throw const SocketException('Network is unreachable'),
        (_) async => ResponseBody.fromString(
              jsonEncode({'fact': 'Recovered after socket reset!', 'length': 29}),
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            ),
      ]);

      final dio = Dio(BaseOptions(baseUrl: 'https://catfact.ninja'))
        ..httpClientAdapter = adapter;

      dio.interceptors.add(
        ExponentialBackoffInterceptor(
          dio: dio,
          connectivityMonitor: connectivity,
          maxRetries: 3,
          baseDelay: const Duration(milliseconds: 500),
          maxJitter: Duration.zero,
          delayFn: (delay) async => recordedDelays.add(delay),
          random: Random(0),
        ),
      );

      final response = await dio.get<Map<String, dynamic>>('/fact');

      expect(response.statusCode, 200);
      expect(response.data?['fact'], 'Recovered after socket reset!');
      expect(adapter.callCount, 3);
      expect(
        recordedDelays,
        [const Duration(milliseconds: 500), const Duration(milliseconds: 1000)],
      );
    });

    test('does not retry DioExceptionType.unknown wrapping non-IOException',
        () async {
      final recordedDelays = <Duration>[];
      final adapter = _ScriptedHttpAdapter([
        (_) async => throw const FormatException('Malformed frame'),
      ]);

      final dio = Dio(BaseOptions(baseUrl: 'https://catfact.ninja'))
        ..httpClientAdapter = adapter;

      dio.interceptors.add(
        ExponentialBackoffInterceptor(
          dio: dio,
          connectivityMonitor: connectivity,
          maxRetries: 3,
          baseDelay: const Duration(milliseconds: 500),
          maxJitter: Duration.zero,
          delayFn: (delay) async => recordedDelays.add(delay),
        ),
      );

      await expectLater(
        () => dio.get<Map<String, dynamic>>('/breeds'),
        throwsA(
          isA<DioException>()
              .having((e) => e.type, 'type', DioExceptionType.unknown)
              .having((e) => e.error, 'error', isA<FormatException>()),
        ),
      );

      expect(adapter.callCount, 1);
      expect(recordedDelays, isEmpty);
    });

    test('retries 429 rate-limit responses and does not retry 4xx client errors',
        () async {
      final rateLimitDelays = <Duration>[];
      final rateLimitAdapter = _ScriptedHttpAdapter([
        (_) async => ResponseBody.fromString('Too Many Requests', 429),
        (_) async => ResponseBody.fromString(
              jsonEncode({'fact': 'Back online', 'length': 11}),
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            ),
      ]);

      final rateLimitDio = Dio(BaseOptions(baseUrl: 'https://catfact.ninja'))
        ..httpClientAdapter = rateLimitAdapter;
      rateLimitDio.interceptors.add(
        ExponentialBackoffInterceptor(
          dio: rateLimitDio,
          connectivityMonitor: connectivity,
          maxJitter: Duration.zero,
          delayFn: (delay) async => rateLimitDelays.add(delay),
        ),
      );

      final response = await rateLimitDio.get<Map<String, dynamic>>('/fact');
      expect(response.statusCode, 200);
      expect(rateLimitAdapter.callCount, 2);
      expect(rateLimitDelays, [const Duration(milliseconds: 500)]);

      final clientErrorDelays = <Duration>[];
      final clientErrorAdapter = _ScriptedHttpAdapter([
        (_) async => ResponseBody.fromString('Bad Request', 400),
      ]);

      final clientErrorDio = Dio(BaseOptions(baseUrl: 'https://catfact.ninja'))
        ..httpClientAdapter = clientErrorAdapter;
      clientErrorDio.interceptors.add(
        ExponentialBackoffInterceptor(
          dio: clientErrorDio,
          connectivityMonitor: connectivity,
          maxJitter: Duration.zero,
          delayFn: (delay) async => clientErrorDelays.add(delay),
        ),
      );

      await expectLater(
        () => clientErrorDio.get<Map<String, dynamic>>('/breeds'),
        throwsA(isA<DioException>()),
      );
      expect(clientErrorAdapter.callCount, 1);
      expect(clientErrorDelays, isEmpty);
    });

    test('honors Retry-After header in seconds and HTTP-date on 429 responses',
        () async {
      var now = DateTime.utc(2026, 11, 25, 12);
      final recordedDelays = <Duration>[];
      final adapter = _ScriptedHttpAdapter([
        (_) async => ResponseBody.fromString(
              'Too Many Requests',
              429,
              headers: {
                'retry-after': ['2'],
              },
            ),
        (_) async => ResponseBody.fromString(
              'Too Many Requests',
              429,
              headers: {
                'retry-after': [
                  HttpDate.format(now.add(const Duration(seconds: 3))),
                ],
              },
            ),
        (_) async => ResponseBody.fromString(
              jsonEncode({'fact': 'Respected Retry-After', 'length': 21}),
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            ),
      ]);

      final dio = Dio(BaseOptions(baseUrl: 'https://catfact.ninja'))
        ..httpClientAdapter = adapter;

      dio.interceptors.add(
        ExponentialBackoffInterceptor(
          dio: dio,
          connectivityMonitor: connectivity,
          maxRetries: 3,
          baseDelay: const Duration(milliseconds: 500),
          maxJitter: Duration.zero,
          totalDeadline: const Duration(seconds: 16),
          clock: () => now,
          delayFn: (delay) async {
            recordedDelays.add(delay);
            now = now.add(delay);
          },
        ),
      );

      final response = await dio.get<Map<String, dynamic>>('/fact');
      expect(response.statusCode, 200);
      expect(response.data?['fact'], 'Respected Retry-After');
      expect(adapter.callCount, 3);
      expect(recordedDelays, [
        const Duration(seconds: 2),
        const Duration(seconds: 3),
      ]);
    });

    test('aborts retries when totalDeadline (16s) or Retry-After exceeds remaining budget',
        () async {
      var now = DateTime.utc(2026, 11, 25, 12);
      final recordedDelays = <Duration>[];
      final observedTimeouts = <Duration?>[];

      final adapter = _ScriptedHttpAdapter([
        (options) async {
          observedTimeouts.add(options.receiveTimeout);
          now = now.add(const Duration(seconds: 7));
          return ResponseBody.fromString('Service Unavailable', 503);
        },
        (options) async {
          observedTimeouts.add(options.receiveTimeout);
          now = now.add(const Duration(seconds: 7));
          return ResponseBody.fromString('Service Unavailable', 503);
        },
        (options) async {
          observedTimeouts.add(options.receiveTimeout);
          return ResponseBody.fromString('Service Unavailable', 503);
        },
      ]);

      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://catfact.ninja',
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 8),
        ),
      )..httpClientAdapter = adapter;

      dio.interceptors.add(
        ExponentialBackoffInterceptor(
          dio: dio,
          connectivityMonitor: connectivity,
          maxRetries: 3,
          baseDelay: const Duration(seconds: 1),
          maxJitter: Duration.zero,
          totalDeadline: const Duration(seconds: 16),
          clock: () => now,
          delayFn: (delay) async {
            recordedDelays.add(delay);
            now = now.add(delay);
          },
        ),
      );

      await expectLater(
        () => dio.get<Map<String, dynamic>>('/breeds'),
        throwsA(isA<DioException>()),
      );

      // Attempt 0 took 7s -> sleeps 1s (8s elapsed, remaining 8s) -> Attempt 1 takes 7s
      // (15s elapsed, remaining 1s) -> next backoff is 2s >= 1s remaining -> stops!
      expect(adapter.callCount, 2);
      expect(recordedDelays, [const Duration(seconds: 1)]);
      expect(observedTimeouts, [
        const Duration(seconds: 8),
        const Duration(seconds: 8),
      ]);

      // Retry-After exceeding remaining deadline aborts immediately with 0 sleep.
      var nowRateLimit = DateTime.utc(2026, 11, 25, 13);
      final rateLimitDelays = <Duration>[];
      final rateLimitAdapter = _ScriptedHttpAdapter([
        (_) async => ResponseBody.fromString(
              'Too Many Requests',
              429,
              headers: {
                'retry-after': ['30'],
              },
            ),
      ]);
      final rateLimitDio = Dio(BaseOptions(baseUrl: 'https://catfact.ninja'))
        ..httpClientAdapter = rateLimitAdapter;
      rateLimitDio.interceptors.add(
        ExponentialBackoffInterceptor(
          dio: rateLimitDio,
          connectivityMonitor: connectivity,
          totalDeadline: const Duration(seconds: 16),
          clock: () => nowRateLimit,
          delayFn: (delay) async {
            rateLimitDelays.add(delay);
            nowRateLimit = nowRateLimit.add(delay);
          },
        ),
      );

      await expectLater(
        () => rateLimitDio.get<Map<String, dynamic>>('/fact'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            429,
          ),
        ),
      );
      expect(rateLimitAdapter.callCount, 1);
      expect(rateLimitDelays, isEmpty);
    });

    test('aborts backoff delay immediately when CancelToken is cancelled',
        () async {
      final delayGate = Completer<void>();
      final delayStarted = Completer<void>();
      final adapter = _ScriptedHttpAdapter([
        (_) async => ResponseBody.fromString('Service Unavailable', 503),
        (_) async => ResponseBody.fromString('{}', 200),
      ]);

      final dio = Dio(BaseOptions(baseUrl: 'https://catfact.ninja'))
        ..httpClientAdapter = adapter;

      dio.interceptors.add(
        ExponentialBackoffInterceptor(
          dio: dio,
          connectivityMonitor: connectivity,
          maxRetries: 3,
          baseDelay: const Duration(seconds: 5),
          maxJitter: Duration.zero,
          delayFn: (_) {
            if (!delayStarted.isCompleted) delayStarted.complete();
            return delayGate.future;
          },
        ),
      );

      final cancelToken = CancelToken();
      final requestFuture = dio.get<Map<String, dynamic>>(
        '/breeds',
        cancelToken: cancelToken,
      );

      await delayStarted.future;
      cancelToken.cancel('User refreshed');

      await expectLater(
        requestFuture,
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.cancel,
          ),
        ),
      );
      expect(adapter.callCount, 1);
    });

    test('DioClientFactory configures 5s connectTimeout and 16s totalDeadline',
        () {
      final dio = DioClientFactory.create(connectivityMonitor: connectivity);

      expect(dio.options.connectTimeout, const Duration(seconds: 5));
      expect(DioClientFactory.totalDeadline, const Duration(seconds: 16));
      final backoff = dio.interceptors
          .whereType<ExponentialBackoffInterceptor>()
          .single;
      expect(backoff.totalDeadline, const Duration(seconds: 16));
    });
  });
}
