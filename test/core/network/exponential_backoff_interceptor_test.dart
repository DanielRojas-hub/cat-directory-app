import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cat_directory_app/core/network/connectivity_monitor.dart';
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
  });
}
