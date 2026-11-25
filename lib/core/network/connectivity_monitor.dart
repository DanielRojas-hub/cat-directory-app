import 'package:connectivity_plus/connectivity_plus.dart';

/// Abstraction for checking and observing device network interface availability.
///
/// Note: Interface connectivity (Wi-Fi/Cellular) does not guarantee upstream
/// reachability; transient HTTP errors are handled by the backoff interceptor.
abstract interface class ConnectivityMonitor {
  /// Returns `false` only when no active network interface is reported
  /// (empty list or exclusively [ConnectivityResult.none]), avoiding false
  /// negatives for interfaces such as USB tethering ([ConnectivityResult.other]).
  Future<bool> get hasConnection;

  /// Emits deduplicated connectivity state changes (`true` = online, `false` = offline).
  Stream<bool> get onStatusChanged;
}

final class ConnectivityPlusMonitor implements ConnectivityMonitor {
  ConnectivityPlusMonitor({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> get hasConnection async {
    final results = await _connectivity.checkConnectivity();
    return _isConnected(results);
  }

  @override
  Stream<bool> get onStatusChanged {
    return _connectivity.onConnectivityChanged
        .map(_isConnected)
        .distinct();
  }

  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }
}
