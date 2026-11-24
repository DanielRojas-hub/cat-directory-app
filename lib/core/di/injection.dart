import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/breeds/data/datasources/breeds_local_datasource.dart';
import '../../features/breeds/data/datasources/breeds_remote_datasource.dart';
import '../../features/breeds/data/repositories/breeds_repository_impl.dart';
import '../../features/breeds/domain/repositories/breeds_repository.dart';
import '../../features/breeds/presentation/bloc/breed_detail_cubit.dart';
import '../../features/breeds/presentation/bloc/breeds_bloc.dart';
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
    )
    ..registerLazySingleton<BreedsRemoteDataSource>(
      () => BreedsRemoteDataSourceImpl(sl<Dio>()),
    )
    ..registerLazySingleton<BreedsLocalDataSource>(
      () => BreedsLocalDataSourceImpl(sl<CacheStore>()),
    )
    ..registerLazySingleton<BreedsRepository>(
      () => BreedsRepositoryImpl(
        remoteDataSource: sl<BreedsRemoteDataSource>(),
        localDataSource: sl<BreedsLocalDataSource>(),
      ),
    )
    ..registerFactory<BreedsBloc>(
      () => BreedsBloc(
        repository: sl<BreedsRepository>(),
        connectivityMonitor: sl<ConnectivityMonitor>(),
      ),
    )
    ..registerFactory<BreedDetailCubit>(
      () => BreedDetailCubit(
        repository: sl<BreedsRepository>(),
      ),
    );
}
