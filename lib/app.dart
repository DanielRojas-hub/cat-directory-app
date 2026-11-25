import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/breeds/presentation/bloc/breeds_bloc.dart';
import 'features/breeds/presentation/bloc/breeds_event.dart';

/// Optional compile-time flag (`--dart-define=SHOW_PERF_OVERLAY=true`) for
/// reproducible performance profiling screenshots in `--profile` mode.
const bool _showPerformanceOverlay = bool.fromEnvironment('SHOW_PERF_OVERLAY');

/// Root widget wiring GoRouter, Material 3 Light/Dark themes, BreedsBloc and
/// foreground/background lifecycle cache revalidation.
class CatDirectoryApp extends StatefulWidget {
  const CatDirectoryApp({
    super.key,
    this.breedsBloc,
    this.router,
  });

  final BreedsBloc? breedsBloc;
  final GoRouter? router;

  @override
  State<CatDirectoryApp> createState() => _CatDirectoryAppState();
}

class _CatDirectoryAppState extends State<CatDirectoryApp>
    with WidgetsBindingObserver {
  late final BreedsBloc _breedsBloc;
  late final bool _ownsBloc;
  late final GoRouter _router;
  late final bool _ownsRouter;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _ownsBloc = widget.breedsBloc == null;
    _breedsBloc = widget.breedsBloc ?? sl<BreedsBloc>();
    _breedsBloc.add(const BreedsStarted());

    _ownsRouter = widget.router == null;
    _router = widget.router ?? createAppRouter();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed && _pausedAt != null) {
      final elapsed = DateTime.now().difference(_pausedAt!);
      _pausedAt = null;
      _breedsBloc.add(BreedsAppResumed(backgroundDuration: elapsed));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_ownsRouter) {
      _router.dispose();
    }
    if (_ownsBloc) {
      _breedsBloc.close().ignore();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BreedsBloc>.value(
      value: _breedsBloc,
      child: MaterialApp.router(
        title: 'Cat Directory',
        debugShowCheckedModeBanner: false,
        showPerformanceOverlay: _showPerformanceOverlay,
        locale: const Locale('es'),
        supportedLocales: const [Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        routerConfig: _router,
      ),
    );
  }
}
