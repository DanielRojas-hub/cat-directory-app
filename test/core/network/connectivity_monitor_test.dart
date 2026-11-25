import 'dart:async';

import 'package:cat_directory_app/core/network/connectivity_monitor.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockConnectivity extends Mock implements Connectivity {}

void main() {
  group('ConnectivityPlusMonitor', () {
    late _MockConnectivity connectivity;
    late ConnectivityPlusMonitor monitor;

    setUp(() {
      connectivity = _MockConnectivity();
      monitor = ConnectivityPlusMonitor(connectivity: connectivity);
    });

    test(
        'returns true for active interfaces including ConnectivityResult.other (USB tethering) and bluetooth',
        () async {
      for (final activeInterface in const [
        ConnectivityResult.wifi,
        ConnectivityResult.mobile,
        ConnectivityResult.ethernet,
        ConnectivityResult.vpn,
        ConnectivityResult.other,
        ConnectivityResult.bluetooth,
      ]) {
        when(() => connectivity.checkConnectivity())
            .thenAnswer((_) async => [activeInterface]);

        expect(
          await monitor.hasConnection,
          isTrue,
          reason: '$activeInterface should not be fast-failed as offline',
        );
      }
    });

    test('fast-fails as offline only when results are empty or exclusively none',
        () async {
      for (final offlineResult in const <List<ConnectivityResult>>[
        [ConnectivityResult.none],
        [ConnectivityResult.none, ConnectivityResult.none],
        [],
      ]) {
        when(() => connectivity.checkConnectivity())
            .thenAnswer((_) async => offlineResult);

        expect(
          await monitor.hasConnection,
          isFalse,
          reason: '$offlineResult should be treated as offline',
        );
      }
    });

    test('returns true when mixed results include none alongside an active interface',
        () async {
      when(() => connectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.none, ConnectivityResult.other],
      );

      expect(await monitor.hasConnection, isTrue);
    });

    test('onStatusChanged deduplicates status transitions and allows other',
        () async {
      final controller = StreamController<List<ConnectivityResult>>();
      addTearDown(controller.close);

      when(() => connectivity.onConnectivityChanged)
          .thenAnswer((_) => controller.stream);

      final emissions = <bool>[];
      final sub = monitor.onStatusChanged.listen(emissions.add);
      addTearDown(sub.cancel);

      controller
        ..add([ConnectivityResult.wifi])
        ..add([ConnectivityResult.mobile])
        ..add([ConnectivityResult.other])
        ..add([ConnectivityResult.none])
        ..add([])
        ..add([ConnectivityResult.other])
        ..add([ConnectivityResult.vpn])
        ..add([ConnectivityResult.ethernet]);

      await Future<void>.delayed(Duration.zero);

      expect(emissions, [true, false, true]);
    });
  });
}
