import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:cat_directory_app/core/errors/app_failure.dart';
import 'package:cat_directory_app/core/network/connectivity_monitor.dart';
import 'package:cat_directory_app/features/breeds/data/datasources/breeds_remote_datasource.dart';
import 'package:cat_directory_app/features/breeds/domain/entities/breed.dart';
import 'package:cat_directory_app/features/breeds/domain/repositories/breeds_repository.dart';
import 'package:cat_directory_app/features/breeds/presentation/bloc/breeds_bloc.dart';
import 'package:cat_directory_app/features/breeds/presentation/bloc/breeds_event.dart';
import 'package:cat_directory_app/features/breeds/presentation/bloc/breeds_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

class _MockBreedsRepository extends Mock implements BreedsRepository {}

class _MockConnectivityMonitor extends Mock implements ConnectivityMonitor {}

Breed _breed(String name) => Breed(
      breed: name,
      country: 'Country',
      origin: 'Natural',
      coat: 'Short',
      pattern: 'Solid',
    );

void main() {
  group('Breed.initials (QA-13)', () {
    test('extracts standard one-word and two-word initials', () {
      expect(_breed('Abyssinian').initials, 'AB');
      expect(_breed('Maine Coon').initials, 'MC');
      expect(_breed('A').initials, 'A');
    });

    test('strips symbols, parentheses, hyphens and emojis cleanly', () {
      expect(_breed('(Persian)').initials, 'PE');
      expect(_breed('Cat - Longhair').initials, 'CL');
      expect(_breed('Cat (Domestic)').initials, 'CD');
      expect(_breed('🐱 Persian').initials, 'PE');
      expect(_breed('American / Wirehair').initials, 'AW');
    });

    test('falls back to ? for empty, whitespace, symbols-only or emoji-only',
        () {
      expect(_breed('').initials, '?');
      expect(_breed('   ').initials, '?');
      expect(_breed('---').initials, '?');
      expect(_breed('🐱🐈').initials, '?');
    });

    test('preserves grapheme clusters and UTF-16 surrogate pairs', () {
      expect(_breed('Égyptian Mau').initials, 'ÉM');
      expect(_breed('e\u0301clair').initials, 'E\u0301C');
      expect(_breed('\u0301abc').initials, 'AB');
      expect(_breed('𐐷a').initials, '𐐏A');
    });
  });

  group('BreedsRemoteDataSourceImpl.fetchRandomFact (QA-8)', () {
    late _MockDio dio;
    late BreedsRemoteDataSourceImpl dataSource;

    setUp(() {
      dio = _MockDio();
      dataSource = BreedsRemoteDataSourceImpl(dio);
    });

    test('throws ServerFailure when API returns empty or whitespace fact',
        () async {
      when(() => dio.get<Map<String, dynamic>>('/fact')).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/fact'),
          data: const {'fact': '   \n\t ', 'length': 6},
          statusCode: 200,
        ),
      );

      await expectLater(
        () => dataSource.fetchRandomFact(),
        throwsA(isA<ServerFailure>()),
      );
    });

    test('returns CatFactModel when API returns non-empty fact', () async {
      when(() => dio.get<Map<String, dynamic>>('/fact')).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/fact'),
          data: const {'fact': 'Cats purr at 26 Hz.', 'length': 19},
          statusCode: 200,
        ),
      );

      final model = await dataSource.fetchRandomFact();
      expect(model.fact, 'Cats purr at 26 Hz.');
    });
  });

  group('BreedsBloc immediate search clear (QA-7)', () {
    late _MockBreedsRepository repository;
    late _MockConnectivityMonitor connectivity;

    setUp(() {
      repository = _MockBreedsRepository();
      connectivity = _MockConnectivityMonitor();
      when(() => connectivity.hasConnection).thenAnswer((_) async => true);
      when(() => connectivity.onStatusChanged)
          .thenAnswer((_) => const Stream<bool>.empty());
      when(() => repository.getCachedFirstPage()).thenReturn(null);
    });

    blocTest<BreedsBloc, BreedsState>(
      'clears search immediately and cancels pending debounced query',
      build: () => BreedsBloc(
        repository: repository,
        connectivityMonitor: connectivity,
        searchDebounceDuration: const Duration(milliseconds: 120),
      ),
      seed: () => BreedsState(
        status: BreedsStatus.loaded,
        breeds: [_breed('Abyssinian'), _breed('Bengal')],
        searchQuery: 'Aby',
        currentPage: 1,
        lastPage: 1,
        total: 2,
      ),
      act: (bloc) {
        bloc
          ..add(const BreedsSearchQueryChanged('Bengal'))
          ..add(const BreedsSearchQueryChanged('', immediate: true));
      },
      wait: const Duration(milliseconds: 180),
      expect: () => [
        isA<BreedsState>()
            .having((s) => s.searchQuery, 'searchQuery', '')
            .having((s) => s.filteredBreeds.length, 'all breeds restored', 2),
      ],
    );
  });
}
