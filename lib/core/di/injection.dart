import 'package:get_it/get_it.dart';

/// Global service locator instance.
final GetIt sl = GetIt.instance;

/// Registers core infrastructure, data sources, repositories and state managers.
Future<void> configureDependencies() async {
  // Dependencies will be registered progressively across feature modules.
}
