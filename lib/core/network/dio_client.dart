import 'package:dio/dio.dart';

import 'connectivity_monitor.dart';
import 'exponential_backoff_interceptor.dart';

/// Factory for configuring the shared [Dio] instance targeting Catfact Ninja.
abstract final class DioClientFactory {
  static const String baseUrl = 'https://catfact.ninja';
  static const Duration connectTimeout = Duration(seconds: 5);
  static const Duration receiveTimeout = Duration(seconds: 8);
  static const Duration sendTimeout = Duration(seconds: 8);
  static const Duration totalDeadline = Duration(seconds: 16);

  static Dio create({
    required ConnectivityMonitor connectivityMonitor,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        sendTimeout: sendTimeout,
        headers: const {
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      ExponentialBackoffInterceptor(
        dio: dio,
        connectivityMonitor: connectivityMonitor,
        totalDeadline: totalDeadline,
      ),
    );

    return dio;
  }
}
