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

    test('returns true for real network interfaces (wifi, mobile, ethernet, vpn)',
        () async {
      for (final validInterface in const [
        ConnectivityResult.wifi,
        ConnectivityResult.mobile,
        ConnectivityResult.ethernet,
        ConnectivityResult.vpn,
      ]) {
        when(() => connectivity.checkConnectivity())
            .thenAnswer((_) async => [validInterface]);

        expect(
          await monitor.hasConnection,
          isTrue,
          reason: '$validInterface should be treated as connected',
        );
      }
    });

    test('returns false for non-internet interfaces (none, bluetooth, other, empty)',
        () async {
      for (final nonInternet in const <List<ConnectivityResult>>[
        [ConnectivityResult.none],
        [ConnectivityResult.bluetooth],
        [ConnectivityResult.other],
        [ConnectivityResult.bluetooth, ConnectivityResult.other],
        [],
      ]) {
        when(() => connectivity.checkConnectivity())
            .thenAnswer((_) async => nonInternet);

        expect(
          await monitor.hasConnection,
          isFalse,
          reason: '$nonInternet should not be treated as connected',
        );
      }
    });

    test('returns true when mixed results include at least one valid interface',
        () async {
      when(() => connectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.bluetooth, ConnectivityResult.wifi],
      );

      expect(await monitor.hasConnection, isTrue);
    });

    test('onStatusChanged filters non-network interfaces and deduplicates events',
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
        ..add([ConnectivityResult.bluetooth])
        ..add([ConnectivityResult.none])
        ..add([ConnectivityResult.other])
        ..add([ConnectivityResult.vpn])
        ..add([ConnectivityResult.ethernet]);

      await Future<void>.delayed(Duration.zero);

      expect(emissions, [true, false, true]);
    });
  });
}
