import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/connectivity_monitor.dart';
import '../network/dio_client.dart';
import '../storage/cache_envelope.dart';

/// Global service locator instance.
final GetIt sl = GetIt.instance;

/// Registers core infrastructure, data sources, repositories and state managers.
Future<void> configureDependencies() async {
  final preferences = await SharedPreferences.getInstance();

  sl
    ..registerSingleton<SharedPreferences>(preferences)
    ..registerLazySingleton<CacheStore>(
      () => SharedPreferencesCacheStore(sl<SharedPreferences>()),
    )
    ..registerLazySingleton<ConnectivityMonitor>(
      ConnectivityPlusMonitor.new,
    )
    ..registerLazySingleton<Dio>(
      () => DioClientFactory.create(
        connectivityMonitor: sl<ConnectivityMonitor>(),
      ),
    );
}
